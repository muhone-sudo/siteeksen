# shellcheck shell=bash
# verify-stack.sh tarafından `source` edilir. Adım 73–74'ün işletmelerini, kategorilerini ve sakinlerini kullanır.
step "75) Sakin vitrini: hizmet alanı, sıralama, telefon yalnız pakette, gizli yorum yok (FAZ M8.1)"

m6svc 19931 services/identity siteeksen_identity "$IDPW"; M8I=$!
m6svc 19932 services/marketplace siteeksen_app "$APPPW"; M8M=$!
env $M6GWENV IDENTITY_SERVICE_URL=http://127.0.0.1:19931 MARKETPLACE_SERVICE_URL=http://127.0.0.1:19932 \
  JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19930 go run ./cmd/gateway >/tmp/verify-m8-gateway.log 2>&1 &
M8G=$!
for _ in $(seq 1 90); do
  curl -fsS http://127.0.0.1:19931/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19932/health >/dev/null 2>&1 \
    && curl -fsS http://127.0.0.1:19930/health >/dev/null 2>&1 && break; sleep 1
done
R1=$(hdr 5550009611); HF1=$(hdr 5550009602)
V0=$(m6 GET "/showcase?category_id=$M6C" "$R1")
VN=$(jget "$V0" "[b['name'].split(' $M6T')[0] for b in d['data']]")
VPH=$(jget "$V0" "{b['name'].split(' $M6T')[0]: b['phone'] is not None for b in d['data']}")
[ "${V0##*|}" = "200" ] && [ "$(jget "$V0" "d['data'][0]['name'].startswith('Pro Tesisat') and d['data'][0]['featured']")" = "True" ] \
  && ! echo "$VN" | grep -q "Uzak Tesisat" && echo "$VN" | grep -q "F5 Yakın şube" && echo "$VN" | grep -q "F5 Uzak şube" \
  && [ "$(jget "$V0" "all(b['distance_m'] is not None for b in d['data'])")" = "True" ] \
  && [ "$(jget "$V0" "all((b['phone'] is not None) == b['featured'] for b in d['data'])")" = "True" ] \
  && [ "$(jget "$V0" "'tax_number' in str(d) or 'balance' in str(d) or 'account_id' in d['data'][0]")" = "False" ] \
  && ok "vitrin: siteyi kapsayan işletmeler (alan dışı yok), ücretli paket başta; telefon yalnız vitrinde telefon hakkı olan pakette; vergi no, bakiye, hesap kimliği yok" \
  || bad "vitrin: ${V0:0:200} adlar=$VN telefon=$VPH"
VC=$(m6 GET "/showcase?category_id=$M6CM" "$R1"); VS=$(m6 GET "/showcase" "$HF1")
[ "$(jget "$VC" "sorted(b['name'].split(' $M6T')[0] for b in d['data'])")" = "['F1 Site Bakım', 'Yönetici Site Bakım']" ] && [ "${VS##*|}" = "403" ] \
  && ok "vitrin kategori süzgeci çalışıyor; sitesi olmayan (yalnız tedarikçi) hesap 403" || bad "süzgeç=${VC: -200} tedarikçi=${VS##*|}"
B5=$(m6sql "SELECT business_id FROM mp_jobs WHERE id='$J5';"); B7=$(m6sql "SELECT business_id FROM mp_jobs WHERE id='$J7';")
D5=$(m6 GET "/showcase/$B5" "$R1"); D7=$(m6 GET "/showcase/$B7" "$R1")
DRAFT=$(m6sql "INSERT INTO mp_businesses (account_id, name, phone, address, city, district, latitude, longitude, service_area, radius_km)
  VALUES ('$F1', 'Taslak $M6T', '+902165550000', 'x', 'İstanbul', 'Kadıköy', 40.99, 29.03, 'KM', 5) RETURNING id;" | head -1)
DD=$(m6 GET "/showcase/$DRAFT" "$R1")
[ "$(jget "$D5" "len(d['reviews'])")" = "0" ] && [ "$(jget "$D7" "[r['rating'] for r in d['reviews']]")" = "[2]" ] \
  && [ "$(jget "$D5" "d['completed_jobs']")" = "1" ] && [ "${DD##*|}" = "404" ] && [ "$(jget "$D5" "type(d['services']).__name__")" = "list" ] \
  && ok "işletme sayfası: hizmet kalemleri ve görünür yorumlar; gizlenen yorum yok; tamamlanan iş sayısı; yayında olmayan işletme 404" \
  || bad "işletme sayfası: gizlenen=${D5: -150} görünür=${D7: -150} taslak=${DD##*|}"

# Paket sınırları (M14): işletme ve işletme başına hizmet kalemi sayısı. Sınırı aşan kayıt silinmez; vitrinde ve eşleşmede görünmez.
PAH=$(hdr 5550009301); HF5=$(hdr 5550009606)
LB0=$(m6 POST /platform/packages "$PAH" '{"name":"Bozuk sınır","monthly_fee_kurus":0,"max_businesses":0}')
LB1=$(m6 POST /platform/packages "$PAH" '{"name":"Bozuk sınır","monthly_fee_kurus":0,"max_services_per_business":1001}')
LPJ() { echo "{\"name\":\"Sınırlı $M6T\",\"monthly_fee_kurus\":0,\"max_businesses\":$1,\"max_services_per_business\":1,\"is_active\":true}"; }
LP=$(m6 POST /platform/packages "$PAH" "$(LPJ 1)"); LPID=$(jget "$LP" "d['id']")
LPA=$(m6sql "SELECT count(*) FROM audit_logs WHERE entity_type='marketplace' AND details->>'package_id'='$LPID'
  AND details->>'max_businesses'='1' AND details->>'max_services_per_business'='1';")
LPD=$(jget "$(m6 GET /platform/packages "$PAH")" "[(p.get('max_businesses', 0), p.get('max_services_per_business', 0)) for p in d['data'] if p['is_default']][0]")
[ "${LB0##*|}" = "422" ] && [ "${LB1##*|}" = "422" ] && [ "${LP##*|}" = "201" ] \
  && [ "$(jget "$LP" "(d['max_businesses'], d['max_services_per_business'])")" = "(1, 1)" ] && [ "$LPD" = "(None, None)" ] && [ "$LPA" = "1" ] \
  && ok "paket sınırları kaydı: işletme ve hizmet kalemi sayısı kaydedilir, işlem kaydına yazılır; 0 ve 1000 üstü 422; boş = sınırsız (varsayılan paket sınırsız)" \
  || bad "paket sınırı kaydı: sıfır=${LB0##*|} fazla=${LB1##*|} kayıt=${LP: -160} işlem=$LPA varsayılan=$LPD"
# Alıcı, kabul edilmiş talebinin işletmesini vitrinden düşse de görür: önce sakin bu işletmeye doğrudan talep açar, tedarikçi kabul edip teklif verir.
m6sql "UPDATE mp_settings SET value_int = 50 WHERE key = 'resident_daily_request_limit';" >/dev/null
LQ=$(m6 POST /requests "$R1" "{\"category_id\":\"$M6C\",\"buyer_type\":\"RESIDENT\",\"description\":\"Banyo bataryası\",\"consent\":true,\"target_business_id\":\"$F5NEAR\"}")
LQID=$(jget "$LQ" "d['request']['id']")
m6sql "UPDATE mp_settings SET value_int = 3 WHERE key = 'resident_daily_request_limit';" >/dev/null
m7open "$LQID"
LQA=$(m6 POST "/supplier/requests/$LQID/accept" "$HF5")
LQO=$(m6 POST "/supplier/requests/$LQID/offers" "$HF5" '{"amount_kurus":90000,"description":"Batarya değişimi","valid_until":"2099-12-31"}')
CP=$(m6 POST /supplier/package "$HF5" "{\"package_id\":\"$LPID\"}")
LBO=$(m6 GET "/requests/$LQID/offers" "$R1"); LBR=$(m6 GET "/requests/$LQID" "$R1")
[ "${LQ##*|}" = "201" ] && [ "${LQA##*|}" = "200" ] && [ "$(jget "$LBO" "[o['business_id'] for o in d['data']]")" = "['$F5NEAR']" ] \
  && [ "$(jget "$LBR" "[a['business_id'] for a in d['accepted']]")" = "['$F5NEAR']" ] \
  && ok "alıcı, talebini kabul etmiş işletmenin teklifini ve kabulünü işletme vitrinden düşse de görür (paket sınırı, kapatma, askı)" \
  || bad "alıcı görünürlüğü: talep=${LQ: -120} kabul=${LQA: -120} teklif=${LQO: -120} teklifler=${LBO: -200} talep=${LBR: -200}"
LV=$(m6 GET "/showcase?category_id=$M6C" "$R1"); LVN=$(jget "$LV" "[b['name'].split(' $M6T')[0] for b in d['data']]")
LDN=$(m6 GET "/showcase/$F5NEAR" "$R1"); LDF=$(m6 GET "/showcase/$F5FAR" "$R1")
LMC=$(m6 GET "/requests/match-count?category_id=$M6C&target_business_id=$F5NEAR" "$R1")
LSB=$(m6 GET /supplier/businesses "$HF5")
[ "${CP##*|}" = "200" ] && jget "$CP" "d['message']" | grep -q "en çok 1" \
  && echo "$LVN" | grep -q "F5 Uzak şube" && ! echo "$LVN" | grep -q "F5 Yakın şube" && [ "${LDN##*|}" = "404" ] && [ "${LDF##*|}" = "200" ] \
  && [ "$(jget "$LMC" "d['count']")" = "0" ] \
  && [ "$(jget "$LSB" "{b['id']: b['over_limit'] for b in d['data']}['$F5NEAR'], {b['id']: b['over_limit'] for b in d['data']}['$F5FAR']")" = "(True, False)" ] \
  && ok "paket düşürülünce sınırı aşan işletme silinmez: en eski yayındaki işletme görünür, sonraki vitrinde (liste ve sayfa 404) ve doğrudan talep eşleşmesinde yok; tedarikçi uyarıyı ve 'sınır dışı' işaretini görür" \
  || bad "sınır görünürlüğü: değişiklik=${CP: -200} vitrin=$LVN yakın=${LDN##*|} uzak=${LDF##*|} eşleşme=${LMC: -40} liste=${LSB: -200}"
BIZ="{\"name\":\"Ek şube\",\"phone\":\"0216 555 00 11\",\"address\":\"Moda Cad. 1\",\"city\":\"İstanbul\",\"district\":\"Kadıköy\",\"latitude\":40.99,\"longitude\":29.03,\"service_area\":\"KM\",\"radius_km\":5,\"category_ids\":[\"$M6C\"]}"
LC=$(m6 POST /supplier/businesses "$HF5" "$BIZ")
m6sql "DELETE FROM mp_business_services WHERE business_id IN ('$F5FAR', '$F5NEAR');" >/dev/null
LS1=$(m6 POST "/supplier/businesses/$F5FAR/services" "$HF5" '{"name":"Musluk değişimi","price_min_kurus":30000,"price_max_kurus":50000,"sort_order":1}')
LS2=$(m6 POST "/supplier/businesses/$F5FAR/services" "$HF5" '{"name":"Petek temizliği","sort_order":2}')
m6sql "INSERT INTO mp_business_services (business_id, account_id, name, sort_order) VALUES ('$F5FAR', '$F5', 'Eski paketten kalan', 2);" >/dev/null
LSD=$(m6 GET "/showcase/$F5FAR" "$R1"); LSL=$(m6 GET "/supplier/businesses/$F5FAR/services" "$HF5")
[ "${LC##*|}" = "409" ] && [ "$(jget "$LC" "d['code']")" = "PACKAGE_LIMIT" ] && [ "${LS1##*|}" = "201" ] && [ "${LS2##*|}" = "409" ] \
  && [ "$(jget "$LS2" "d['code']")" = "PACKAGE_LIMIT" ] && [ "$(jget "$LSD" "[s['name'] for s in d['services']]")" = "['Musluk değişimi']" ] \
  && [ "$(jget "$LSL" "sorted((s['name'], s['over_limit']) for s in d['data'])")" = "[('Eski paketten kalan', True), ('Musluk değişimi', False)]" ] \
  && ok "sınırda ekleme yok: yeni işletme ve fazladan hizmet kalemi 409 PACKAGE_LIMIT; eski paketten kalan fazla kalem vitrinde yok, tedarikçi listesinde işaretli" \
  || bad "sınırda ekleme: işletme=${LC: -120} hizmet1=${LS1##*|} hizmet2=${LS2: -120} vitrin=${LSD: -200} liste=${LSL: -200}"
m6 PUT "/platform/packages/$LPID" "$PAH" "$(LPJ 3)" >/dev/null
P1PID=""; for i in 1 2 3; do (m6 POST /supplier/businesses "$HF5" "$BIZ" | sed 's/.*|//' >"/tmp/verify-m14-par.$i") & P1PID="$P1PID $!"; done
for p in $P1PID; do wait "$p"; done
LPAR=$(for i in 1 2 3; do cat "/tmp/verify-m14-par.$i"; echo; done | sort | tr '\n' ' ')
LNC=$(m6sql "SELECT count(*) FROM mp_businesses WHERE account_id='$F5' AND status <> 'CLOSED';")
[ "$LPAR" = "201 409 409 " ] && [ "$LNC" = "3" ] \
  && ok "eşzamanlı işletme ekleme: sınır 3, mevcut 2 → üç paralel istekten tam biri kabul (taslak dahil sayılır)" \
  || bad "eşzamanlı ekleme: yanıtlar=$LPAR kapatılmamış=$LNC"
m6sql "UPDATE mp_businesses SET status='CLOSED' WHERE account_id='$F5' AND id NOT IN ('$F5FAR', '$F5NEAR');
  DELETE FROM mp_business_services WHERE business_id='$F5FAR';
  UPDATE mp_supplier_accounts SET package_id='$M6FREE', next_package_id=NULL, package_renews_at=NULL WHERE id='$F5';" >/dev/null
LV2=$(m6 GET "/showcase?category_id=$M6C" "$R1"); LVN2=$(jget "$LV2" "[b['name'].split(' $M6T')[0] for b in d['data']]")
echo "$LVN2" | grep -q "F5 Uzak şube" && echo "$LVN2" | grep -q "F5 Yakın şube" \
  && ok "sınırsız pakete dönülünce gizlenen işletme hemen vitrine geri gelir (veri kaybı yok)" || bad "geri dönüş: vitrin=$LVN2"
kill_tree "$M8I"; kill_tree "$M8M"; kill_tree "$M8G"
