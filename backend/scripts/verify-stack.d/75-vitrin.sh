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
kill_tree "$M8I"; kill_tree "$M8M"; kill_tree "$M8G"
