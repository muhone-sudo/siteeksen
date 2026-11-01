# shellcheck shell=bash
# verify-stack.sh tarafından `source` edilir. Adım 70'in tedarikçilerini (5550009201 incelemede, 5550009202 taslak) kullanır.
step "71) Platform yönetimi: hesap ve işletme incelemesi, bildirim, vitrin, kategori/paket/ayar (FAZ M4)"

$PSQL -q -c "INSERT INTO users (first_name, last_name, phone, password_hash, password_set_at, kvkk_consent_at, roles)
  SELECT 'Platform', 'Yönetici', '+905550009301', password_hash, now(), now(), ARRAY['PLATFORM_ADMIN'] FROM users WHERE phone='+905551234567'
  ON CONFLICT (phone) DO NOTHING;"
m4svc() { env DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=$3 DB_PASSWORD="$4" DB_NAME=siteeksen DB_SSLMODE=disable \
  STORAGE_BACKEND=local STORAGE_LOCAL_DIR=/tmp/verify-m3-files \
  JWT_SECRET=verify-secret-key-at-least-32-chars PORT=$1 go run ./$2 >/tmp/verify-m4-$(basename "$2").log 2>&1 & }
m4svc 19951 services/identity siteeksen_identity "$IDPW"; M4I=$!
m4svc 19952 services/marketplace siteeksen_app "$APPPW"; M4M=$!
M4GWENV=""
for n in FINANCE COMMUNITY IOT NOTIFICATION EXPENSE ASSET BULLETIN CONTRACT DOCUMENT ENERGY ESG INVENTORY NPS PACKAGE PARKING \
         PATROL PERSONNEL RESERVATION SETTINGS SMART_COLLECTION SURVEY VISITOR BANKING GOVERNANCE; do
  M4GWENV="$M4GWENV ${n}_SERVICE_URL=http://127.0.0.1:9"
done
env $M4GWENV IDENTITY_SERVICE_URL=http://127.0.0.1:19951 MARKETPLACE_SERVICE_URL=http://127.0.0.1:19952 \
  JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19950 go run ./cmd/gateway >/tmp/verify-m4-gateway.log 2>&1 &
M4G=$!
for _ in $(seq 1 90); do
  curl -fsS http://127.0.0.1:19951/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19952/health >/dev/null 2>&1 \
    && curl -fsS http://127.0.0.1:19950/health >/dev/null 2>&1 && break; sleep 1
done
M4=http://127.0.0.1:19950/api/v1/market
m4login() { curl -s -X POST "http://127.0.0.1:19950/api/v1/auth/login" -H "$J" -d "{\"phone\":\"$1\",\"password\":\"Demo123!\"}" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'; }
PA="Authorization: Bearer $(m4login 5550009301)"; S1="Authorization: Bearer $(m4login 5550009201)"
S2="Authorization: Bearer $(m4login 5550009202)"; MG="Authorization: Bearer $(m4login 5551234567)"
m4() { curl -s -w '|%{http_code}' -X "$1" "$M4$2" -H "$3" -H "$J" ${4:+-d "$4"}; }
jget() { python3 -c "import json,sys; d=json.loads(sys.argv[1].rsplit('|',1)[0]); print(eval(sys.argv[2]))" "$1" "$2" 2>/dev/null; }
ACC1=$($PSQL -t -A -c "SELECT a.id FROM mp_supplier_accounts a JOIN users u ON u.id=a.user_id WHERE u.phone='+905550009201';")
ACC2=$($PSQL -t -A -c "SELECT a.id FROM mp_supplier_accounts a JOIN users u ON u.id=a.user_id WHERE u.phone='+905550009202';")
DOCID=$($PSQL -t -A -c "SELECT id FROM mp_account_documents WHERE account_id='$ACC1' AND doc_type='ID_CARD' LIMIT 1;")

# Yetki
P1=$(code "$M4/platform/accounts" -H "$S1"); P2=$(code "$M4/platform/accounts" -H "$MG")
LQ=$(m4 GET "/platform/accounts?status=REVIEW" "$PA")
[ "$P1$P2" = "403403" ] && [ "$(jget "$LQ" "[a['owner_phone'] for a in d['data'] if a['id']=='$ACC1']")" = "['+905550009201']" ] \
  && ok "platform uçları: tedarikçi ve site yöneticisi 403; platform kuyruğunda incelemedeki hesap sahibinin adı/telefonuyla" \
  || bad "platform yetki/kuyruk: tedarikçi=$P1 yönetici=$P2 kuyruk=${LQ:0:200}"
PD=$(curl -s -o /dev/null -w '%{http_code}' "$M4/platform/documents/$DOCID/file" -H "$PA")
PL=$($PSQL -t -A -c "SELECT count(*) FROM mp_document_access_logs WHERE document_id='$DOCID' AND accessor='PLATFORM';")
[ "$PD" = "200" ] && [ "$PL" = "1" ] && ok "platform belgeyi açtı; erişim kaydı PLATFORM olarak yazıldı" || bad "platform belge: $PD kayıt=$PL"

# Ret → tedarikçiye bildirim → yeniden gönderim → onay
R0=$(m4 POST "/platform/accounts/$ACC1/reject" "$PA" '{"reason":""}')
R1=$(m4 POST "/platform/accounts/$ACC1/reject" "$PA" "{\"reason\":\"Kimlik belgesi okunmuyor\",\"reject_document_ids\":[\"$DOCID\"]}")
DS=$($PSQL -t -A -c "SELECT status||'|'||review_note FROM mp_account_documents WHERE id='$DOCID';")
NT=$(m4 GET /supplier/notifications "$S1")
[ "${R0##*|}" = "422" ] && [ "$(jget "$R1" "d['account']['status']")" = "DRAFT" ] && [ "$DS" = "REJECTED|Kimlik belgesi okunmuyor" ] \
  && [ "$(jget "$NT" "d['unread']")" = "1" ] && grep -q 'okunmuyor' <<<"$NT" && [ "$(jget "$R1" "d['notification']['in_app']")" = "SENT" ] \
  && ok "ret: gerekçesiz 422; hesap taslağa döndü, seçilen belge reddedildi; tedarikçiye gerekçeli uygulama içi bildirim (okunmamış 1)" \
  || bad "ret: gerekçesiz=${R0##*|} ret=${R1: -160} belge=$DS bildirim=${NT:0:200}"
NS=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE supplier_account_id='$ACC1' AND property_id IS NULL AND topic='market.supplier.rejected';")
[ "$NS" -ge 1 ] && ok "bildirim sitesiz kayıt olarak tedarikçi hesabına bağlı ($NS)" || bad "sitesiz bildirim kaydı yok"
RS=$(m4 POST /supplier/account/submit "$S1")
UPID=$(curl -s -X POST "$M4/supplier/documents" -H "$S1" -F "doc_type=ID_CARD" -F "file=@/tmp/verify-m3-kimlik.png" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null)
RS2=$(m4 POST /supplier/account/submit "$S1")
AP=$(m4 POST "/platform/accounts/$ACC1/approve" "$PA"); AP2=$(m4 POST "/platform/accounts/$ACC1/approve" "$PA")
PEND=$($PSQL -t -A -c "SELECT count(*) FROM mp_account_documents WHERE account_id='$ACC1' AND status='PENDING';")
grep -q 'kimlik belgesi' <<<"$RS" && [ -n "$UPID" ] && [ "$(jget "$RS2" "d['status']")" = "REVIEW" ] \
  && [ "$(jget "$AP" "d['account']['status']")" = "APPROVED" ] && [ "${AP2##*|}" = "409" ] && [ "$PEND" = "0" ] \
  && ok "reddedilen belge eksik sayıldı; yeni kimlik yüklenip yeniden gönderildi; onaylandı (bekleyen belge kalmadı); ikinci onay 409" \
  || bad "yeniden gönderim/onay: eksik=${RS: -80} yeni=$UPID gönder=${RS2: -40} onay=${AP: -60} tekrar=${AP2##*|} bekleyen=$PEND"

# İşletme yayını
BID=$($PSQL -t -A -c "SELECT id FROM mp_businesses WHERE account_id='$ACC1' AND status='REVIEW' LIMIT 1;")
SID=$($PSQL -t -A -c "SELECT id FROM mp_business_services WHERE business_id='$BID' AND photo_key IS NOT NULL LIMIT 1;")
V0=$($PSQL -t -A -c "SELECT count(*) FROM mp_business_public WHERE id='$BID';")
BA=$(m4 POST "/platform/businesses/$BID/approve" "$PA")
V1=$($PSQL -t -A -c "SELECT count(*) FROM mp_business_public WHERE id='$BID';")
VS=$(PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_app -d siteeksen -q -t -A -c "BEGIN; SELECT set_config('app.property_id','$DEMO_PROPERTY',true); SELECT count(*) FROM mp_business_services_public WHERE business_id='$BID'; COMMIT;" | awk 'NF && !/-/' | tail -1)
VPH=$($PSQL -t -A -c "SELECT COALESCE(phone,'gizli') FROM mp_business_public WHERE id='$BID';")
# Fotoğraf denetimi (M13.4): onaylanmadan vitrinde yok; onaydan (burada doğrudan kayıtla) sonra açık
PH0=$(code "$M4/services/$SID/photo" -H "$MG")
$PSQL -q -c "UPDATE photo_moderation SET status='APPROVED', decision_source='PLATFORM', decided_at=now()
  WHERE storage_key=(SELECT photo_key FROM mp_business_services WHERE id='$SID');"
PH1=$(code "$M4/services/$SID/photo" -H "$MG"); PH2=$(code "$M4/services/$SID/photo" -H "$S2")
[ "$PH0" = "404" ] && [ "$V0" = "0" ] && [ "$(jget "$BA" "d['business']['status']")" = "PUBLISHED" ] && [ "$V1" = "1" ] && [ "$VS" = "2" ] && [ "$VPH" = "gizli" ] \
  && [ "$PH1$PH2" = "200200" ] \
  && ok "işletme yayına alındı: vitrinde görünüyor (site kapsamında 2 hizmet kalemi okunuyor), ücretsiz pakette telefon gizli; fotoğraf denetimden geçmeden 404, onaydan sonra sakine ve başka tedarikçiye açık" \
  || bad "yayın: önce=$V0 onay=${BA: -80} sonra=$V1 hizmet=$VS telefon=$VPH foto onaysız=$PH0 onaylı=$PH1/$PH2"
NB=$(m4 POST /supplier/businesses "$S1" "{\"name\":\"Kemal Tesisat Bostancı\",\"phone\":\"02165550012\",\"address\":\"Bağdat Cad.\",\"city\":\"İstanbul\",\"district\":\"Kadıköy\",\"latitude\":40.96,\"longitude\":29.09,\"service_area\":\"KM\",\"radius_km\":5,\"category_ids\":[\"$M3CAT1\"]}")
NBID=$(jget "$NB" "d['id']"); m4 POST "/supplier/businesses/$NBID/submit" "$S1" >/dev/null
BR0=$(m4 POST "/platform/businesses/$NBID/reject" "$PA" '{"reason":""}')
BR=$(m4 POST "/platform/businesses/$NBID/reject" "$PA" '{"reason":"Konum adresle uyuşmuyor"}')
SEEN=$(jget "$(m4 GET "/supplier/businesses/$NBID" "$S1")" "d['status']+'|'+d['review_note']")
[ "${BR0##*|}" = "422" ] && [ "$SEEN" = "REJECTED|Konum adresle uyuşmuyor" ] \
  && ok "işletme reddi: gerekçesiz 422; gerekçe tedarikçinin işletme sayfasında" || bad "işletme reddi: ${BR0##*|} / $SEEN"
S2B=$(m4 POST /supplier/businesses "$S2" "{\"name\":\"Selin Temizlik\",\"phone\":\"02165550013\",\"address\":\"Üsküdar\",\"city\":\"İstanbul\",\"district\":\"Üsküdar\",\"latitude\":41.02,\"longitude\":29.01,\"service_area\":\"CITY\",\"category_ids\":[\"$M3CAT2\"]}")
S2BID=$(jget "$S2B" "d['id']"); m4 POST "/supplier/businesses/$S2BID/submit" "$S2" >/dev/null
SA=$(m4 POST "/platform/businesses/$S2BID/approve" "$PA")
[ "${SA##*|}" = "409" ] && grep -q ACCOUNT_NOT_APPROVED <<<"$SA" && ok "hesabı onaylanmamış tedarikçinin işletmesi yayına alınamıyor (409)" || bad "onaysız hesap yayını: $SA"

# Askıya alma vitrinden düşürür
SU0=$(m4 POST "/platform/accounts/$ACC1/suspend" "$PA" '{"reason":""}')
SU=$(m4 POST "/platform/accounts/$ACC1/suspend" "$PA" '{"reason":"Şikâyet incelemesi"}')
V2=$($PSQL -t -A -c "SELECT count(*) FROM mp_business_public WHERE id='$BID';")
RI=$(m4 POST "/platform/accounts/$ACC1/reinstate" "$PA")
V3=$($PSQL -t -A -c "SELECT count(*) FROM mp_business_public WHERE id='$BID';")
[ "${SU0##*|}" = "422" ] && [ "$(jget "$SU" "d['account']['status']")" = "SUSPENDED" ] && [ "$V2" = "0" ] && [ "$(jget "$RI" "d['account']['status']")" = "APPROVED" ] && [ "$V3" = "1" ] \
  && ok "askıya alma: gerekçesiz 422; askıdaki hesabın işletmesi vitrinden düştü, yeniden etkinleşince döndü" \
  || bad "askı: gerekçesiz=${SU0##*|} askı=${SU: -60} vitrin=$V2 geri=${RI: -60} vitrin=$V3"

# Kategori, paket, ayar
C0=$(m4 POST /platform/categories "$PA" '{"name":"Boya","request_fee_kurus":6000,"buyer_scope":"HER"}')
C1=$(m4 POST /platform/categories "$PA" '{"name":"Boya badana","request_fee_kurus":6000,"buyer_scope":"BOTH"}'); CID=$(jget "$C1" "d['id']")
C2=$(m4 PUT "/platform/categories/$CID" "$PA" '{"name":"Boya badana","request_fee_kurus":7500,"buyer_scope":"BOTH"}')
C3=$(m4 POST /platform/categories "$S1" '{"name":"Sızma","request_fee_kurus":1,"buyer_scope":"BOTH"}')
CA=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE entity_type='marketplace' AND details->>'category_id'='$CID' AND details->>'request_fee_kurus'='7500';")
m4 PUT "/platform/categories/$CID" "$PA" '{"name":"Boya badana","request_fee_kurus":7500,"buyer_scope":"BOTH","is_active":false}' >/dev/null
INMETA=$(jget "$(m4 GET /meta "$MG")" "any(c['id']=='$CID' for c in d['categories'])")
[ "${C0##*|}" = "422" ] && [ "${C1##*|}" = "201" ] && [ "$(jget "$C2" "d['request_fee_kurus']")" = "7500" ] && [ "${C3##*|}" = "403" ] && [ "$CA" -ge 1 ] && [ "$INMETA" = "False" ] \
  && ok "kategori: geçersiz alıcı türü 422; eklendi; ücret değişikliği işlem kaydında (7500); tedarikçi 403; pasif kategori meta'da yok" \
  || bad "kategori: tür=${C0##*|} ekle=${C1: -60} ücret=${C2: -60} tedarikçi=${C3##*|} kayıt=$CA meta=$INMETA"
PK=$(m4 POST /platform/packages "$PA" '{"name":"Usta Pro","monthly_fee_kurus":29900,"fee_discount_pct":25,"included_requests":5,"monthly_sms":50,"priority_access":true,"phone_in_showcase":true,"rank_weight":10,"is_active":true}')
PKD=$(m4 PUT /platform/packages/7a000000-0000-4000-8000-000000000001 "$PA" '{"name":"Ücretsiz","monthly_fee_kurus":100,"is_active":true}')
PKB=$(m4 POST /platform/packages "$PA" '{"name":"Bozuk","monthly_fee_kurus":100,"fee_discount_pct":150}')
[ "${PK##*|}" = "201" ] && [ "${PKD##*|}" = "422" ] && [ "${PKB##*|}" = "422" ] \
  && ok "paket: 'Usta Pro' eklendi; varsayılan pakete aidat konamıyor (veritabanı kısıtı, 422); indirim %150 → 422" \
  || bad "paket: ekle=${PK: -60} varsayılan=${PKD: -80} indirim=${PKB##*|}"
ST=$(m4 PUT /platform/settings/priority_window_minutes "$PA" '{"value":45}')
ST2=$(m4 PUT /platform/settings/olmayan_ayar "$PA" '{"value":1}'); ST3=$(m4 PUT /platform/settings/request_ttl_hours "$PA" '{"value":-1}')
MV=$(jget "$(m4 GET /meta "$MG")" "[s['value'] for s in d['settings'] if s['key']=='priority_window_minutes'][0]")
[ "$(jget "$ST" "d['value']")" = "45" ] && [ "${ST2##*|}${ST3##*|}" = "404422" ] && [ "$MV" = "45" ] \
  && ok "ayar: öncelik penceresi 45 dk yapıldı ve meta'da görünüyor; bilinmeyen anahtar 404, eksi değer 422" \
  || bad "ayar: kaydet=${ST: -60} bilinmeyen=${ST2##*|} eksi=${ST3##*|} meta=$MV"
m4 PUT /platform/settings/priority_window_minutes "$PA" '{"value":30}' >/dev/null
kill_tree "$M4I"; kill_tree "$M4M"; kill_tree "$M4G"
