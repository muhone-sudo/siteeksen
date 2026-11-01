# shellcheck shell=bash
# verify-stack.sh tarafından `source` edilir. Adım 73–75'in tedarikçilerini ve kategorilerini kullanır.
step "76) Yönetim alımı: site talebi yalnız yöneticiden, kurul/denetçi okur; seçilen teklif → onay bekleyen gider (080, FAZ M10)"

m6svc 19931 services/identity siteeksen_identity "$IDPW"; M10I=$!
m6svc 19932 services/marketplace siteeksen_app "$APPPW"; M10M=$!
m6svc 19934 services/expense siteeksen_app "$APPPW"; M10E=$!
M10GW=""
for n in FINANCE COMMUNITY IOT NOTIFICATION ASSET BULLETIN CONTRACT DOCUMENT ENERGY ESG INVENTORY NPS PACKAGE PARKING \
         PATROL PERSONNEL RESERVATION SETTINGS SMART_COLLECTION SURVEY VISITOR BANKING GOVERNANCE; do
  M10GW="$M10GW ${n}_SERVICE_URL=http://127.0.0.1:9"
done
env $M10GW IDENTITY_SERVICE_URL=http://127.0.0.1:19931 MARKETPLACE_SERVICE_URL=http://127.0.0.1:19932 EXPENSE_SERVICE_URL=http://127.0.0.1:19934 \
  JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19930 go run ./cmd/gateway >/tmp/verify-m10-gateway.log 2>&1 &
M10G=$!
for _ in $(seq 1 90); do
  curl -fsS http://127.0.0.1:19931/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19932/health >/dev/null 2>&1 \
    && curl -fsS http://127.0.0.1:19934/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19930/health >/dev/null 2>&1 && break; sleep 1
done
for r in AUDITOR BOARD_MEMBER; do
  $PSQL -q -c "INSERT INTO users (first_name, last_name, phone, password_hash, password_set_at, kvkk_consent_at, roles, active_property_id)
    SELECT 'Görevli', '$r', '+9055500097$([ $r = AUDITOR ] && echo 11 || echo 12)', password_hash, now(), now(), ARRAY['RESIDENT'], '$DEMO_PROPERTY'
    FROM users WHERE phone='+905551234567' ON CONFLICT (phone) DO NOTHING;
    INSERT INTO property_roles (user_id, property_id, role, is_active)
    SELECT id, '$DEMO_PROPERTY', '$r', true FROM users WHERE phone='+9055500097$([ $r = AUDITOR ] && echo 11 || echo 12)'
    AND NOT EXISTS (SELECT 1 FROM property_roles pr JOIN users u ON u.id = pr.user_id WHERE u.phone='+9055500097$([ $r = AUDITOR ] && echo 11 || echo 12)');"
done
AU=$(hdr 5550009711); BM=$(hdr 5550009712); MG=$(hdr 5551234567); HF1=$(hdr 5550009602); R2=$(hdr 5550009612)
$PSQL -q -c "UPDATE mp_supplier_accounts SET trade_name='F1 Tesisat Ltd', tax_number='1234567890', tax_office='Kadıköy' WHERE id='$F1';"
m6fund "$F1" 50000
A0=$(m6 POST /requests "$AU" "{\"category_id\":\"$M6CM\",\"buyer_type\":\"MANAGEMENT\",\"description\":\"Denetçi açamaz\"}")
B0=$(m6 POST /requests "$BM" "{\"category_id\":\"$M6CM\",\"buyer_type\":\"MANAGEMENT\",\"description\":\"Kurul açamaz\"}")
QY=$(m6 POST /requests "$MG" "{\"category_id\":\"$M6CM\",\"buyer_type\":\"MANAGEMENT\",\"description\":\"Çatı izolasyonu\"}"); REQY=$(jget "$QY" "d['request']['id']")
AL=$(m6 GET "/requests?scope=management" "$AU"); BL=$(m6 GET "/requests/$REQY" "$BM"); RS=$(m6 GET "/requests?scope=management" "$R2")
[ "${A0##*|}" = "403" ] && [ "${B0##*|}" = "403" ] && [ "${QY##*|}" = "201" ] && [ "$(jget "$AL" "len([x for x in d['data'] if x['id']=='$REQY'])")" = "1" ] \
  && [ "${BL##*|}" = "200" ] && [ "${RS##*|}" = "403" ] \
  && ok "site talebi: yönetici açar; denetçi ve kurul üyesi açamaz (403) ama site taleplerini okur (200); sakin site taleplerini göremez (403)" \
  || bad "site talebi yetkileri: denetçi=${A0##*|} kurul=${B0##*|} yönetici=${QY: -80} denetçi-liste=${AL: -80} kurul-tek=${BL##*|} sakin=${RS##*|}"
m6sql "UPDATE mp_request_dispatch SET visible_at = now() - interval '1 second' WHERE request_id='$REQY';" >/dev/null
AY=$(m6 POST "/supplier/requests/$REQY/accept" "$HF1")
OY=$(m6 POST "/supplier/requests/$REQY/offers" "$HF1" '{"amount_kurus":1850000,"description":"Çatı su yalıtımı, 120 m²","valid_until":"2099-12-31"}')
AS=$(m6 POST "/requests/$REQY/offers/$(jget "$OY" "d['id']")/select" "$AU"); MS=$(m6 POST "/requests/$REQY/offers/$(jget "$OY" "d['id']")/select" "$MG")
JY=$(m6 GET "/requests/$REQY/job" "$BM"); JR=$(m6 GET "/requests/$REQ7/job" "$R2")
[ "${AS##*|}" = "403" ] && [ "${MS##*|}" = "200" ] && [ "$(jget "$JY" "(d['vendor']['trade_name'], d['vendor']['tax_number'], d['amount_kurus'])")" = "('F1 Tesisat Ltd', '1234567890', 1850000)" ] \
  && [ "$(jget "$JR" "'vendor' in d")" = "False" ] \
  && ok "teklifi yönetici seçer (denetçi 403); site alımının işinde tedarikçinin fatura bilgisi (unvan, vergi no) var; sakin alımında yok" \
  || bad "seçim/fatura bilgisi: kabul=${AY: -80} denetçi=${AS##*|} yönetici=${MS: -80} iş=${JY: -200} sakin=${JR: -100}"
EXC=$(m6sql "SELECT id FROM expense_categories WHERE property_id='$DEMO_PROPERTY' ORDER BY sort_order LIMIT 1;")
EX=$(curl -s -w '|%{http_code}' -X POST "http://127.0.0.1:19930/api/v1/expenses" -H "$MG" -H "$J" -d "{\"category_id\":\"$EXC\",\"description\":\"Usta & Hizmet: Çatı izolasyonu — F1 Tesisat Ltd\",\"amount\":18500,\"expense_date\":\"$(date +%F)\",\"is_invoiced\":false,\"invoice_reason\":\"Usta & Hizmet teklifi seçildi; fatura iş sonunda\",\"vendor_name\":\"F1 Tesisat Ltd\",\"vendor_tax_id\":\"1234567890\",\"notes\":\"Usta & Hizmet talep $REQY\"}")
EXID=$(jget "$EX" "d['expense']['id']")
EXR=$(m6sql "SELECT status || '|' || amount || '|' || vendor_tax_id || '|' || vendor_name FROM expenses WHERE id='$EXID';")
[ "${EX##*|}" = "201" ] && [ "$EXR" = "PENDING|18500.00|1234567890|F1 Tesisat Ltd" ] \
  && ok "seçilen teklif mevcut gider ucuyla onay bekleyen gidere çevrildi (tutar, vergi no, unvan; PENDING — kurul onayı akışı aynı)" \
  || bad "gider: ${EX: -200} satır=$EXR"
kill_tree "$M10I"; kill_tree "$M10M"; kill_tree "$M10E"; kill_tree "$M10G"
