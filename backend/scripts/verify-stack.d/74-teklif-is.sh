# shellcheck shell=bash
# verify-stack.sh tarafından `source` edilir. Adım 73'ün hesaplarını, kategorilerini ve sakinlerini kullanır
# (P1 ücretli, F1–F5 ücretsiz, R1/R2 sakin, MG yönetici; REQ2'yi P1 dahil hakla kabul etti).
step "74) Teklif, mesaj, iş, puan, geçersiz talep iadesi, yorum denetimi, gelir raporu, saklama (079, FAZ M7)"

M7GWENV=""
for n in FINANCE COMMUNITY IOT NOTIFICATION EXPENSE ASSET BULLETIN CONTRACT DOCUMENT ENERGY ESG INVENTORY NPS PACKAGE PARKING \
         PATROL PERSONNEL RESERVATION SMART_COLLECTION SURVEY VISITOR BANKING GOVERNANCE; do
  M7GWENV="$M7GWENV ${n}_SERVICE_URL=http://127.0.0.1:9"
done
m6svc 19931 services/identity siteeksen_identity "$IDPW"; M7I=$!
m6svc 19932 services/marketplace siteeksen_app "$APPPW"; M7M=$!
m6svc 19933 services/settings siteeksen_app "$APPPW"; M7S=$!
env $M7GWENV IDENTITY_SERVICE_URL=http://127.0.0.1:19931 MARKETPLACE_SERVICE_URL=http://127.0.0.1:19932 SETTINGS_SERVICE_URL=http://127.0.0.1:19933 \
  JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19930 go run ./cmd/gateway >/tmp/verify-m7-gateway.log 2>&1 &
M7G=$!
for _ in $(seq 1 90); do
  curl -fsS http://127.0.0.1:19931/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19932/health >/dev/null 2>&1 \
    && curl -fsS http://127.0.0.1:19933/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19930/health >/dev/null 2>&1 && break; sleep 1
done
HP1=$(hdr 5550009601); HF1=$(hdr 5550009602); HF2=$(hdr 5550009603); HF3=$(hdr 5550009604); HF4=$(hdr 5550009605); HFAR=$(hdr 5550009608)
R1=$(hdr 5550009611); R2=$(hdr 5550009612); MG=$(hdr 5551234567)
$PSQL -q -c "INSERT INTO users (first_name, last_name, phone, password_hash, password_set_at, kvkk_consent_at, roles)
  SELECT 'Platform', 'M7', '+905550009701', password_hash, now(), now(), ARRAY['PLATFORM_ADMIN'] FROM users WHERE phone='+905551234567'
  ON CONFLICT (phone) DO NOTHING;"
PA=$(hdr 5550009701)
m7req() { m6 POST /requests "$1" "{\"category_id\":\"$2\",\"buyer_type\":\"$3\",\"description\":\"$4\",\"consent\":true}"; }
m7open() { m6sql "UPDATE mp_request_dispatch SET visible_at = now() - interval '1 second' WHERE request_id='$1' AND visible_at > now();" >/dev/null; }

# Teklif (M7.1)
Q5=$(m7req "$R2" "$M6C" RESIDENT "Salon kalorifer peteği sızdırıyor"); REQ5=$(jget "$Q5" "d['request']['id']"); m7open "$REQ5"
for h in "$HF1" "$HF2" "$HF3"; do m6 POST "/supplier/requests/$REQ5/accept" "$h" >/dev/null; done
OX=$(m6 POST "/supplier/requests/$REQ5/offers" "$HF4" '{"amount_kurus":100000,"description":"Petek değişimi","valid_until":"2099-12-31"}')
O0=$(m6 POST "/supplier/requests/$REQ5/offers" "$HF1" '{"amount_kurus":0,"description":"x","valid_until":"2099-12-31"}')
O1=$(m6 POST "/supplier/requests/$REQ5/offers" "$HF1" '{"amount_kurus":150000,"description":"Petek sökülüp contası değişir","valid_until":"2099-12-31"}')
O1B=$(m6 POST "/supplier/requests/$REQ5/offers" "$HF1" '{"amount_kurus":140000,"description":"Petek sökülüp contası değişir (indirimli)","valid_until":"2099-12-31"}')
O2=$(m6 POST "/supplier/requests/$REQ5/offers" "$HF2" '{"amount_kurus":120000,"description":"Yeni petek takılır","valid_until":"2099-12-31"}')
O3=$(m6 POST "/supplier/requests/$REQ5/offers" "$HF3" '{"amount_kurus":90000,"description":"Geçici onarım","valid_until":"2099-12-31"}')
W3=$(m6 POST "/supplier/offers/$(jget "$O3" "d['id']")/withdraw" "$HF3")
BO=$(m6 GET "/requests/$REQ5/offers" "$R2")
[ "${OX##*|}" = "403" ] && [ "${O0##*|}" = "422" ] && [ "$(jget "$O1" "d['id']")" = "$(jget "$O1B" "d['id']")" ] && [ "$(jget "$O1B" "d['amount_kurus']")" = "140000" ] \
  && [ "${W3##*|}" = "200" ] && [ "$(jget "$BO" "sorted((o['business_name'][:2], o['amount_kurus']) for o in d['data'])")" = "[('F1', 140000), ('F2', 120000)]" ] \
  && [ "$(jget "$BO" "all(o.get('business_phone') for o in d['data'])")" = "True" ] \
  && [ "$(m6sql "SELECT count(*) FROM notifications n JOIN users u ON u.id=n.recipient_user_id WHERE n.topic='market.offer.new' AND u.phone='+905550009612';")" -ge 2 ] \
  && ok "teklif: kabul etmemiş hesap 403, tutarsız 422; etkin teklif güncellendi (aynı kayıt); geri çekilen alıcıya görünmüyor; alıcı teklifleri işletme telefonu ve puanıyla yan yana görüyor; alıcıya bildirim" \
  || bad "teklif: kabulsüz=${OX: -60} sıfır=${O0##*|} güncel=${O1B: -80} geri=${W3##*|} alıcı=${BO:0:300}"

# Mesaj (M7.3)
D1=$(m6sql "SELECT id FROM mp_request_dispatch WHERE request_id='$REQ5' AND account_id='$F1';")
MB=$(m6 POST "/requests/$REQ5/messages/$D1" "$R2" '{"body":"Daire B-2, akşam 7 uygun"}')
MS=$(m6 POST "/supplier/requests/$REQ5/messages" "$HF1" '{"body":"Tamam, 19:00 da geliyorum"}')
ML=$(m6 GET "/supplier/requests/$REQ5/messages" "$HF1"); MLB=$(m6 GET "/requests/$REQ5/messages/$D1" "$R2")
MN=$(m6 GET "/requests/$REQ5/messages/$D1" "$R1"); MF4=$(m6 GET "/supplier/requests/$REQ5/messages" "$HF4"); MFAR=$(m6 GET "/supplier/requests/$REQ5/messages" "$HFAR")
MF4W=$(m6 POST "/supplier/requests/$REQ5/messages" "$HF4" '{"body":"araya giriyorum"}')
[ "${MB##*|}" = "201" ] && [ "${MS##*|}" = "201" ] && [ "$(jget "$ML" "len(d['data'])")" = "2" ] && [ "$(jget "$MLB" "[m['sender_side'] for m in d['data']]")" = "['SUPPLIER', 'BUYER']" ] \
  && [ "${MN##*|}" = "404" ] && [ "${MF4##*|}" = "403" ] && [ "${MFAR##*|}" = "404" ] && [ "${MF4W##*|}" = "403" ] \
  && [ "$(m6sql "SELECT count(*) FROM notifications WHERE topic='market.message' AND (supplier_account_id='$F1' OR recipient_user_id=(SELECT id FROM users WHERE phone='+905550009612'));")" -ge 2 ] \
  && ok "mesaj: alıcı ve kabul eden tedarikçi yazışıyor (iki yöne bildirim); komşu 404, kabul etmemiş tedarikçi okuyamıyor/yazamıyor 403, gönderilmemiş 404" \
  || bad "mesaj: alıcı=${MB##*|} tedarikçi=${MS##*|} liste=${ML: -80} komşu=${MN##*|} kabulsüz=${MF4##*|}/${MF4W##*|} gönderilmemiş=${MFAR##*|}"

# Seçim (M7.2)
LB=$(m6sql "SELECT count(*) FROM mp_wallet_ledger;")
SE=$(m6 POST "/requests/$REQ5/offers/$(jget "$O1B" "d['id']")/select" "$R2")
SEN=$(m6 POST "/requests/$REQ5/offers/$(jget "$O2" "d['id']")/select" "$R1")
SO=$(m6sql "SELECT string_agg(a.trade_name || ':' || o.status, ',' ORDER BY a.trade_name) FROM mp_offers o JOIN mp_supplier_accounts a ON a.id=o.account_id WHERE o.request_id='$REQ5' AND o.status <> 'WITHDRAWN';")
NDEC=$(m6sql "SELECT count(*) FROM notifications WHERE topic='market.offer.declined' AND supplier_account_id='$F2' AND payload->>'request_id'='$REQ5';")
O2N=$(m6 POST "/supplier/requests/$REQ5/offers" "$HF2" '{"amount_kurus":100000,"description":"yeniden","valid_until":"2099-12-31"}')
[ "${SE##*|}" = "200" ] && [ "${SEN##*|}" = "404" ] && [ "$(m6sql "SELECT count(*) FROM mp_jobs WHERE request_id='$REQ5';")" = "1" ] \
  && [ "$SO" = "M6 +905550009602:ACCEPTED,M6 +905550009603:DECLINED" ] && [ "$NDEC" = "1" ] && [ "${O2N##*|}" = "409" ] \
  && [ "$(m6sql "SELECT status FROM mp_requests WHERE id='$REQ5';")" = "CLOSED" ] && [ "$(m6sql "SELECT count(*) FROM mp_wallet_ledger;")" = "$LB" ] \
  && ok "teklif seçimi: tek iş oluştu, talep kapandı, diğer teklif reddedildi ve bildirildi, yeni teklif 409; komşu seçemez 404; defter değişmedi" \
  || bad "seçim: ${SE: -120} komşu=${SEN##*|} teklifler=$SO bildirim=$NDEC yeniden=${O2N##*|}"
QM2=$(m6 POST /requests "$MG" "{\"category_id\":\"$M6CM\",\"buyer_type\":\"MANAGEMENT\",\"description\":\"Çatı oluğu temizliği\"}"); REQ6=$(jget "$QM2" "d['request']['id']"); m7open "$REQ6"
m6 POST "/supplier/requests/$REQ6/accept" "$HF1" >/dev/null
m6 POST "/supplier/requests/$REQ6/offers" "$HF1" '{"amount_kurus":300000,"description":"Oluk temizliği","valid_until":"2099-12-31"}' >/dev/null
L6=$(m6sql "SELECT count(*) FROM mp_wallet_ledger;")
CR=$(m6 POST "/requests/$REQ6/close" "$MG")
[ "${CR##*|}" = "200" ] && [ "$(m6sql "SELECT r.status || '|' || o.status FROM mp_requests r JOIN mp_offers o ON o.request_id=r.id WHERE r.id='$REQ6';")" = "CANCELLED|DECLINED" ] \
  && [ "$(m6sql "SELECT count(*) FROM mp_wallet_ledger;")" = "$L6" ] \
  && ok "talep teklif seçilmeden kapatıldı: etkin teklif reddedildi, kabul ücreti iade edilmedi (defter değişmedi)" \
  || bad "kapatma: ${CR: -100} durum=$(m6sql "SELECT status FROM mp_requests WHERE id='$REQ6';")"

# İş: tamamlandı → itiraz → onay; otomatik tamamlama (M7.4) ve puan (M7.5)
J5=$(m6sql "SELECT id FROM mp_jobs WHERE request_id='$REQ5';")
JC0=$(m6 POST "/requests/$REQ5/job/confirm" "$R2"); JD0=$(m6 POST "/supplier/jobs/$J5/done" "$HF2")
RV0=$(m6 POST "/requests/$REQ5/review" "$R2" '{"rating":5,"comment":"erken"}')
JD=$(m6 POST "/supplier/jobs/$J5/done" "$HF1")
JNOTE=$(m6sql "SELECT count(*) FROM notifications n JOIN users u ON u.id=n.recipient_user_id WHERE n.topic='market.job.completed' AND u.phone='+905550009612';")
JX0=$(m6 POST "/requests/$REQ5/job/dispute" "$R2" '{"note":""}'); JX=$(m6 POST "/requests/$REQ5/job/dispute" "$R2" '{"note":"Sızıntı devam ediyor"}')
m6sql "UPDATE mp_jobs SET supplier_done_at = now() - interval '30 days' WHERE id='$J5';" >/dev/null
sleep 5
JS1=$(m6sql "SELECT status FROM mp_jobs WHERE id='$J5';")
JC=$(m6 POST "/requests/$REQ5/job/confirm" "$R2")
[ "${JC0##*|}" = "409" ] && [ "${JD0##*|}" = "404" ] && [ "${RV0##*|}" = "409" ] && [ "$(jget "$JD" "d['status']")" = "DONE_CLAIMED" ] && [ "$JNOTE" -ge 1 ] \
  && [ "${JX0##*|}" = "422" ] && [ "$(jget "$JX" "d['status']")" = "DISPUTED" ] && [ "$JS1" = "DISPUTED" ] \
  && [ "$(jget "$JC" "(d['status'], d['completion_source'])")" = "('COMPLETED', 'BUYER')" ] \
  && ok "iş: tamamlandı bildirimi öncesi onay 409, başkasının işi 404, tamamlanmamışa puan 409; tedarikçi bildirdi (alıcıya bildirim); gerekçesiz itiraz 422; itirazdaki iş süresi geçse de kendiliğinden tamamlanmadı; alıcı onayıyla tamamlandı" \
  || bad "iş: erken onay=${JC0##*|} başkası=${JD0##*|} erken puan=${RV0##*|} bildirim=${JD: -60}/$JNOTE itiraz=${JX0##*|}/${JX: -60} otomatik=$JS1 onay=${JC: -80}"
Q7=$(m7req "$R2" "$M6C" RESIDENT "Banyo bataryası"); REQ7=$(jget "$Q7" "d['request']['id']"); m7open "$REQ7"
m6 POST "/supplier/requests/$REQ7/accept" "$HF2" >/dev/null
O7=$(m6 POST "/supplier/requests/$REQ7/offers" "$HF2" '{"amount_kurus":80000,"description":"Batarya değişimi","valid_until":"2099-12-31"}')
m6 POST "/requests/$REQ7/offers/$(jget "$O7" "d['id']")/select" "$R2" >/dev/null
J7=$(m6sql "SELECT id FROM mp_jobs WHERE request_id='$REQ7';")
m6 POST "/supplier/jobs/$J7/done" "$HF2" >/dev/null
m6sql "UPDATE mp_jobs SET supplier_done_at = now() - interval '8 days' WHERE id='$J7';" >/dev/null
for _ in $(seq 1 15); do [ "$(m6sql "SELECT status FROM mp_jobs WHERE id='$J7';")" = "COMPLETED" ] && break; sleep 1; done
[ "$(m6sql "SELECT status || '|' || completion_source FROM mp_jobs WHERE id='$J7';")" = "COMPLETED|AUTO" ] \
  && [ "$(m6sql "SELECT count(*) FROM notifications WHERE topic='market.job.completed' AND dedupe_key LIKE 'market.job.auto:$J7%';")" -ge 2 ] \
  && ok "alıcı 7 gün (ayar) yanıt vermeyince iş kendiliğinden tamamlandı; iki tarafa bildirildi" \
  || bad "otomatik tamamlama: $(m6sql "SELECT status || '|' || COALESCE(completion_source,'-') FROM mp_jobs WHERE id='$J7';")"
B5=$(m6sql "SELECT business_id FROM mp_jobs WHERE id='$J5';")
RN=$(m6 POST "/requests/$REQ5/review" "$R1" '{"rating":1,"comment":"komşu"}')
RV=$(m6 POST "/requests/$REQ5/review" "$R2" '{"rating":4,"comment":"İşini temiz yaptı"}'); RV2=$(m6 POST "/requests/$REQ5/review" "$R2" '{"rating":1,"comment":"tekrar"}')
RW=$(m6 POST "/requests/$REQ7/review" "$R2" '{"rating":2,"comment":"Geç geldi"}')
RVID=$(jget "$RV" "d['id']")
RP=$(m6 POST "/supplier/reviews/$RVID/reply" "$HF1" '{"reply":"Teşekkür ederiz"}'); RP2=$(m6 POST "/supplier/reviews/$RVID/reply" "$HF1" '{"reply":"ikinci"}')
RPO=$(m6 POST "/supplier/reviews/$RVID/reply" "$HF2" '{"reply":"başkası"}')
[ "${RN##*|}" = "404" ] && [ "${RV##*|}" = "201" ] && [ "${RV2##*|}" = "409" ] && [ "${RW##*|}" = "201" ] \
  && [ "$(m6sql "SELECT rating_sum || '/' || rating_count || '/' || completed_jobs FROM mp_businesses WHERE id='$B5';")" = "4/1/1" ] \
  && [ "${RP##*|}" = "200" ] && [ "${RP2##*|}" = "409" ] && [ "${RPO##*|}" = "404" ] \
  && ok "puan: komşu 404; tamamlanan işe bir kez (ikinci 409), otomatik tamamlanana da; işletme özeti 4/1 ve 1 iş; tedarikçi bir kez yanıtladı, başkası 404" \
  || bad "puan: komşu=${RN##*|} ilk=${RV: -80} ikinci=${RV2##*|} otomatik=${RW##*|} özet=$(m6sql "SELECT rating_sum || '/' || rating_count || '/' || completed_jobs FROM mp_businesses WHERE id='$B5';") yanıt=${RP##*|}/${RP2##*|}/${RPO##*|}"

# Geçersiz talep bildirimi ve iade (M7.6)
F3B0=$(m6sql "SELECT balance_kurus FROM mp_supplier_accounts WHERE id='$F3';")
DX=$(m6 POST "/supplier/requests/$REQ5/dispute" "$HF4" '{"reason_code":"FAKE","note":"Kabul etmeden bildirim"}')
D3A=$(m6 POST "/supplier/requests/$REQ5/dispute" "$HF3" '{"reason_code":"UNREACHABLE","note":"Alıcıya üç gün ulaşılamadı"}')
D3B=$(m6 POST "/supplier/requests/$REQ5/dispute" "$HF3" '{"reason_code":"UNREACHABLE","note":"Alıcıya üç gün ulaşılamadı"}')
DP1=$(m6 POST "/supplier/requests/$REQ2/dispute" "$HP1" '{"reason_code":"WRONG_CATEGORY","note":"Talep kombi değil boya işiydi"}')
DF2=$(m6 POST "/supplier/requests/$REQ7/dispute" "$HF2" '{"reason_code":"OTHER","note":"Ücret yüksek geldi, iade istiyorum"}')
DQ=$(m6 GET "/platform/disputes?status=OPEN" "$PA"); DS=$(code "$M6/platform/disputes" -H "$HF1")
DA0=$(m6 POST "/platform/disputes/$(jget "$D3A" "d['id']")/approve" "$PA" '{"note":""}')
DA=$(m6 POST "/platform/disputes/$(jget "$D3A" "d['id']")/approve" "$PA" '{"note":"Alıcı numarası kullanım dışı"}')
DA2=$(m6 POST "/platform/disputes/$(jget "$D3A" "d['id']")/approve" "$PA" '{"note":"tekrar onay"}')
P1I0=$(m6sql "SELECT period_included_left FROM mp_supplier_accounts WHERE id='$P1';")
DAP=$(m6 POST "/platform/disputes/$(jget "$DP1" "d['id']")/approve" "$PA" '{"note":"Kategori yanlış seçilmiş"}')
DR=$(m6 POST "/platform/disputes/$(jget "$DF2" "d['id']")/reject" "$PA" '{"note":"Fiyat anlaşmazlığı geçersiz talep değildir"}')
F3B1=$(m6sql "SELECT balance_kurus FROM mp_supplier_accounts WHERE id='$F3';")
RF=$(m6sql "SELECT count(*) || '|' || COALESCE(sum(amount_kurus),0) FROM mp_wallet_ledger WHERE kind='REFUND' AND account_id='$F3';")
[ "${DX##*|}" = "403" ] && [ "${D3A##*|}" = "201" ] && [ "${D3B##*|}" = "409" ] && [ "${DS}" = "403" ] && [ "$(jget "$DQ" "len(d['data'])")" -ge 3 ] \
  && [ "${DA0##*|}" = "422" ] && [ "${DA##*|}" = "200" ] && [ "${DA2##*|}" = "409" ] && [ "$((F3B1 - F3B0))" = "10000" ] && [ "$RF" = "1|10000" ] \
  && [ "$(jget "$DAP" "d['dispute']['status']")" = "APPROVED" ] && [ "$(m6sql "SELECT period_included_left FROM mp_supplier_accounts WHERE id='$P1';")" = "$((P1I0 + 1))" ] \
  && [ "$(m6sql "SELECT count(*) FROM mp_wallet_ledger WHERE kind='REFUND' AND account_id='$P1';")" = "0" ] \
  && [ "$(jget "$DR" "d['dispute']['status']")" = "REJECTED" ] && [ "$(m6sql "SELECT count(*) FROM mp_wallet_ledger WHERE kind='REFUND' AND account_id='$F2';")" = "0" ] \
  && [ "$(m6sql "SELECT count(*) FROM notifications WHERE topic='market.dispute.resolved' AND supplier_account_id IN ('$F3','$P1','$F2');")" -ge 3 ] \
  && ok "geçersiz talep: kabul etmeyen bildiremez 403, ikinci bildirim 409, kuyruk yalnız platformda; gerekçesiz karar 422; onayda 100 TL bakiyeye iade (tek REFUND), ikinci onay 409; dahil hakla kabulde hak geri verildi (defter satırı yok); ret iade etmedi; kararlar bildirildi" \
  || bad "itiraz: kabulsüz=${DX##*|} ilk=${D3A##*|} ikinci=${D3B##*|} kuyruk=$DS/${DQ:0:60} gerekçesiz=${DA0##*|} onay=${DA: -80} tekrar=${DA2##*|} bakiye=$F3B0→$F3B1 iade=$RF hak=${DAP: -80} ret=${DR: -60}"

# Yorum denetimi (M7.7)
H0=$(m6 POST "/platform/reviews/$RVID/hide" "$PA" '{"reason":""}'); HS=$(code -X POST "$M6/platform/reviews/$RVID/hide" -H "$HF1" -H "$J" -d '{"reason":"kendi yorumumu gizle"}')
H1=$(m6 POST "/platform/reviews/$RVID/hide" "$PA" '{"reason":"Kişisel bilgi içeriyor"}')
PUB=$(PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_app -d siteeksen -q -t -A -c "BEGIN; SELECT set_config('app.property_id','$DEMO_PROPERTY',true); SELECT count(*) FROM mp_reviews_public WHERE id='$RVID'; COMMIT;" | awk 'NF && !/-/' | tail -1)
[ "${H0##*|}" = "422" ] && [ "$HS" = "403" ] && [ "${H1##*|}" = "200" ] && [ "$PUB" = "0" ] \
  && [ "$(m6sql "SELECT count(*) FROM mp_reviews WHERE id='$RVID' AND hidden_at IS NOT NULL AND hidden_reason='Kişisel bilgi içeriyor';")" = "1" ] \
  && [ "$(m6sql "SELECT rating_sum || '/' || rating_count FROM mp_businesses WHERE id='$B5';")" = "0/0" ] \
  && [ "$(m6sql "SELECT count(*) FROM audit_logs WHERE event='market.review.hidden';")" -ge 1 ] \
  && ok "yorum denetimi: gerekçesiz 422, tedarikçi 403; gizlenen yorum vitrinde yok, veritabanında gerekçesiyle duruyor, puan özetinden çıktı; işlem kaydında" \
  || bad "yorum gizleme: gerekçesiz=${H0##*|} tedarikçi=$HS gizle=${H1: -60} vitrin=$PUB"

# Gelir raporu (M7.8)
TODAY=$(m6sql "SELECT to_char(now() AT TIME ZONE 'Europe/Istanbul', 'YYYY-MM-DD');")
RVN=$(m6 GET "/platform/revenue?from=$TODAY&to=$TODAY" "$PA"); RVB=$(m6 GET "/platform/revenue?from=$TODAY&to=2000-01-01" "$PA")
EXP=$(m6sql "SELECT COALESCE(-sum(amount_kurus) FILTER (WHERE kind IN ('PACKAGE_FEE','REQUEST_FEE')),0) - COALESCE(sum(amount_kurus) FILTER (WHERE kind='REFUND'),0)
  || '|' || COALESCE(sum(amount_kurus),0) FROM mp_wallet_ledger WHERE created_at >= date_trunc('day', now() AT TIME ZONE 'Europe/Istanbul') AT TIME ZONE 'Europe/Istanbul';")
[ "$(jget "$RVN" "str(d['net_kurus']) + '|' + str(d['ledger_total_kurus'])")" = "$EXP" ] && [ "$(jget "$RVN" "d['refunds_kurus'] >= 10000 and d['request_fees_kurus'] > 0")" = "True" ] \
  && [ "${RVB##*|}" = "422" ] && [ "$(code "$M6/platform/revenue?from=$TODAY&to=$TODAY" -H "$HF1")" = "403" ] \
  && ok "gelir raporu: aidat + talep ücreti − iade = defterden hesaplanan ($EXP); dönem hatası 422; tedarikçi 403" \
  || bad "gelir raporu: ${RVN:0:300} beklenen=$EXP ters dönem=${RVB##*|}"

# Saklama (M7.9): site saklama süresi tanımlar; kapanmış eski talebin iletişim ve mesajları anonimleşir
RS=$(code -X PUT "http://127.0.0.1:19930/api/v1/retention-rules/MARKET_REQUEST" -H "$MG" -H "$J" -d '{"retention_months":1,"justification":"Usta & Hizmet: iş sonrası uyuşmazlık için bir ay"}')
m6sql "UPDATE mp_requests SET closed_at = now() - interval '2 months' WHERE id IN ('$REQ5','$REQ6');" >/dev/null
RR=$(curl -s -X POST "http://127.0.0.1:19930/api/v1/retention-rules/run" -H "$MG" -H "$J" -d '{}')
AN=$(m6sql "SELECT string_agg(COALESCE(c.contact_name,'-') || ':' || COALESCE(c.contact_phone,'-'), ',' ORDER BY r.created_at) FROM mp_request_contacts c JOIN mp_requests r ON r.id=c.request_id WHERE r.id IN ('$REQ5','$REQ6','$REQ7');")
AM=$(m6sql "SELECT count(*) FILTER (WHERE anonymized_at IS NOT NULL AND body='[imha edildi]') || '|' || count(*) FROM mp_messages WHERE request_id='$REQ5';")
KEEP=$(m6sql "SELECT (SELECT count(*) FROM mp_requests WHERE id IN ('$REQ5','$REQ6')) || '|' || (SELECT count(*) FROM mp_wallet_ledger l JOIN mp_request_dispatch d ON d.id=l.dispatch_id WHERE d.request_id='$REQ5');")
[ "$RS" = "200" ] && [ "$AN" = "[imha edildi]:-,[imha edildi]:-,Sakin M6-2:+905550009612" ] && [ "$AM" = "2|2" ] && [ "$KEEP" = "2|4" ] \
  && [ "$(m6sql "SELECT count(*) FROM data_destruction_log WHERE category='MARKET_REQUEST' AND record_count >= 2;")" -ge 1 ] \
  && ok "saklama: süresi dolan kapanmış taleplerin adı/telefonu ve mesajları anonimleşti, yeni talep korundu; talep ve defter kayıtları duruyor; imha kaydı yazıldı" \
  || bad "saklama: kural=$RS iletişim=$AN mesaj=$AM kalan=$KEEP çalıştırma=${RR: -200}"

DRIFT=$(m6sql "SELECT count(*) FROM mp_supplier_accounts a LEFT JOIN (SELECT account_id, sum(amount_kurus) s FROM mp_wallet_ledger GROUP BY account_id) l ON l.account_id=a.id WHERE a.balance_kurus <> COALESCE(l.s,0);")
[ "$DRIFT" = "0" ] && ok "para tutarlılığı: her hesapta bakiye = defter toplamı (fark 0)" || bad "bakiye/defter farkı olan hesap: $DRIFT"
kill_tree "$M7I"; kill_tree "$M7M"; kill_tree "$M7S"; kill_tree "$M7G"
