# shellcheck shell=bash
# verify-stack.sh tarafından `source` edilir.
step "70) Tedarikçi hesabı, belgeler, işletmeler, hizmet kalemleri (FAZ M3)"

# İki tedarikçi (kayıt akışı adım 68'de sınandı; burada doğrudan açılır)
for P in 9201 9202; do
  $PSQL -q -c "INSERT INTO users (first_name, last_name, phone, password_hash, password_set_at, kvkk_consent_at, roles)
    SELECT 'Tedarikçi', '$P', '+90555000$P', password_hash, now(), now(), ARRAY['SUPPLIER'] FROM users WHERE phone='+905551234567'
    ON CONFLICT (phone) DO NOTHING;"
done
M3CAT1=$($PSQL -t -A -c "INSERT INTO mp_categories (name, request_fee_kurus, buyer_scope) VALUES ('Tesisat', 4000, 'RESIDENT')
  ON CONFLICT (parent_id, name) DO UPDATE SET is_active = true RETURNING id;")
M3CAT2=$($PSQL -t -A -c "INSERT INTO mp_categories (name, request_fee_kurus, buyer_scope) VALUES ('Site temizliği', 30000, 'MANAGEMENT')
  ON CONFLICT (parent_id, name) DO UPDATE SET is_active = true RETURNING id;")
M3CATX=$($PSQL -t -A -c "INSERT INTO mp_categories (name, request_fee_kurus, is_active) VALUES ('Kapalı kategori', 1000, false)
  ON CONFLICT (parent_id, name) DO UPDATE SET is_active = false RETURNING id;")

rm -rf /tmp/verify-m3-files && mkdir -p /tmp/verify-m3-files
m3svc() { env DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=$3 DB_PASSWORD="$4" DB_NAME=siteeksen DB_SSLMODE=disable \
  STORAGE_BACKEND=local STORAGE_LOCAL_DIR=/tmp/verify-m3-files \
  JWT_SECRET=verify-secret-key-at-least-32-chars PORT=$1 go run ./$2 >/tmp/verify-m3-$(basename "$2").log 2>&1 & }
m3svc 19961 services/identity siteeksen_identity "$IDPW"; M3I=$!
m3svc 19962 services/marketplace siteeksen_app "$APPPW"; M3M=$!
M3GWENV=""
for n in FINANCE COMMUNITY IOT NOTIFICATION EXPENSE ASSET BULLETIN CONTRACT DOCUMENT ENERGY ESG INVENTORY NPS PACKAGE PARKING \
         PATROL PERSONNEL RESERVATION SETTINGS SMART_COLLECTION SURVEY VISITOR BANKING GOVERNANCE; do
  M3GWENV="$M3GWENV ${n}_SERVICE_URL=http://127.0.0.1:9"
done
env $M3GWENV IDENTITY_SERVICE_URL=http://127.0.0.1:19961 MARKETPLACE_SERVICE_URL=http://127.0.0.1:19962 \
  JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19960 go run ./cmd/gateway >/tmp/verify-m3-gateway.log 2>&1 &
M3G=$!
for _ in $(seq 1 90); do
  curl -fsS http://127.0.0.1:19961/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19962/health >/dev/null 2>&1 \
    && curl -fsS http://127.0.0.1:19960/health >/dev/null 2>&1 && break; sleep 1
done
M3=http://127.0.0.1:19960/api/v1/market
m3login() { curl -s -X POST "http://127.0.0.1:19960/api/v1/auth/login" -H "$J" -d "{\"phone\":\"$1\",\"password\":\"Demo123!\"}" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'; }
S1="Authorization: Bearer $(m3login 5550009201)"; S2="Authorization: Bearer $(m3login 5550009202)"; MG="Authorization: Bearer $(m3login 5551234567)"
m3() { curl -s -w '|%{http_code}' -X "$1" "$M3$2" -H "$3" -H "$J" ${4:+-d "$4"}; }
jget() { python3 -c "import json,sys; d=json.loads(sys.argv[1].rsplit('|',1)[0]); print(eval(sys.argv[2]))" "$1" "$2" 2>/dev/null; }

# Hesap
A0=$(m3 POST /supplier/account "$S1" '{"trade_name":"Kemal Tesisat","tax_number":"1234567890","tax_office":"Kadıköy"}')
A1=$(m3 POST /supplier/account "$S1" '{"trade_name":"Kemal Tesisat","tax_number":"12345","tax_office":"Kadıköy","terms_accepted":true}')
A2=$(m3 POST /supplier/account "$S1" '{"trade_name":"Kemal Tesisat","tax_number":"","tax_office":"","terms_accepted":true}')
A3=$(m3 POST /supplier/account "$S1" '{"trade_name":"Tekrar","terms_accepted":true}')
A2S=$(jget "$A2" "d['status']+'|'+d['package']['name']")
[ "${A0##*|}" = "422" ] && [ "${A1##*|}" = "422" ] && [ "${A2##*|}" = "201" ] && [ "$A2S" = "DRAFT|Ücretsiz" ] && [ "${A3##*|}" = "409" ] \
  && ok "hesap: sözleşmesiz 422, vergi no biçimi 422; açıldı (taslak, ücretsiz paket); ikinci kez 409" \
  || bad "hesap açma: sözleşmesiz=${A0##*|} vergi=${A1##*|} açılış=${A2: -80} ikinci=${A3##*|}"
SB=$(m3 POST /supplier/account/submit "$S1")
grep -q 'vergi numarası' <<<"$SB" && grep -q 'kimlik belgesi' <<<"$SB" && [ "${SB##*|}" = "422" ] \
  && ok "eksik bilgi ve belgeyle incelemeye gönderme 422 ve eksikler tek tek sayılıyor" || bad "eksik gönderim: $SB"
AU=$(m3 PUT /supplier/account "$S1" '{"trade_name":"Kemal Tesisat","tax_number":"1234567890","tax_office":"Kadıköy"}')
[ "${AU##*|}" = "200" ] && ok "taslak hesap bilgileri güncellendi" || bad "hesap güncelleme: $AU"

# Belgeler
printf '%%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%%%EOF\n' > /tmp/verify-m3-vergi.pdf
printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82' > /tmp/verify-m3-kimlik.png
echo "düz metin" > /tmp/verify-m3-metin.txt
up() { curl -s -w '|%{http_code}' -X POST "$M3/supplier/documents" -H "$1" -F "doc_type=$2" -F "file=@$3"; }
UT=$(up "$S1" TAX_PLATE /tmp/verify-m3-metin.txt)
UX=$(up "$S1" PASAPORT /tmp/verify-m3-vergi.pdf)
UP=$(up "$S1" TAX_PLATE /tmp/verify-m3-vergi.pdf); DP=$(jget "$UP" "d['id']")
UI=$(up "$S1" ID_CARD /tmp/verify-m3-kimlik.png); DI=$(jget "$UI" "d['id']")
SHA_DB=$($PSQL -t -A -c "SELECT sha256 FROM mp_account_documents WHERE id='$DP';")
SHA_FILE=$(sha256sum /tmp/verify-m3-vergi.pdf | cut -d' ' -f1)
[ "${UT##*|}" = "415" ] && [ "${UX##*|}" = "422" ] && [ "${UP##*|}" = "201" ] && [ "${UI##*|}" = "201" ] && [ "$SHA_DB" = "$SHA_FILE" ] \
  && ok "belge: metin dosyası 415, bilinmeyen tür 422; PDF ve PNG yüklendi; SHA-256 dosyayla birebir ($SHA_FILE)" \
  || bad "belge yükleme: metin=${UT##*|} tür=${UX##*|} pdf=${UP: -60} png=${UI: -40} sha db=$SHA_DB dosya=$SHA_FILE"
DL1=$(curl -s -o /tmp/verify-m3-indir.pdf -w '%{http_code}' "$M3/supplier/documents/$DP/file" -H "$S1")
m3 POST /supplier/account "$S2" '{"trade_name":"Selin Temizlik","tax_number":"9876543210","tax_office":"Üsküdar","terms_accepted":true}' >/dev/null
DL2=$(code "$M3/supplier/documents/$DP/file" -H "$S2")
DL3=$(code "$M3/supplier/documents/$DP/file" -H "$MG")
LOGN=$($PSQL -t -A -c "SELECT count(*) FROM mp_document_access_logs WHERE document_id='$DP' AND accessor='OWNER';")
[ "$DL1" = "200" ] && cmp -s /tmp/verify-m3-indir.pdf /tmp/verify-m3-vergi.pdf && [ "$DL2" = "404" ] && [ "$DL3" = "403" ] && [ "$LOGN" = "1" ] \
  && ok "belge indirme: sahibi aynı dosyayı aldı ve erişim kaydı yazıldı; başka tedarikçi 404 (varlığı sızmıyor), yönetici 403" \
  || bad "belge indirme: sahibi=$DL1 başka=$DL2 yönetici=$DL3 kayıt=$LOGN"
DD=$(m3 DELETE "/supplier/documents/$DP" "$S1")
[ "${DD##*|}" = "409" ] && ok "açılmış (erişim kaydı olan) belge silinemiyor 409" || bad "açılmış belge silme: $DD"
SB2=$(m3 POST /supplier/account/submit "$S1")
AU2=$(m3 PUT /supplier/account "$S1" '{"trade_name":"Değişti","tax_number":"1234567890","tax_office":"Kadıköy"}')
[ "$(jget "$SB2" "d['status']")" = "REVIEW" ] && [ "${AU2##*|}" = "409" ] \
  && ok "bilgi ve belgeler tamamken incelemeye gönderildi (REVIEW); incelemedeki hesap bilgisi değiştirilemiyor 409" \
  || bad "inceleme: gönder=${SB2: -60} değiştir=${AU2##*|}"

# İşletmeler
BJ() { echo "{\"name\":\"$1\",\"description\":\"$2\",\"phone\":\"0216 555 00 11\",\"address\":\"Moda Cad. 1\",\"city\":\"İstanbul\",\"district\":\"Kadıköy\",\"latitude\":$3,\"longitude\":29.03,\"service_area\":\"$4\",\"radius_km\":$5,\"category_ids\":[$6]}"; }
B0=$(m3 POST /supplier/businesses "$S1" "$(BJ '' x 40.99 KM 10 "\"$M3CAT1\"")")
B1=$(m3 POST /supplier/businesses "$S1" "$(BJ Merkez x 95 KM 10 "\"$M3CAT1\"")")
B2=$(m3 POST /supplier/businesses "$S1" "$(BJ Merkez x 40.99 KM 0 "\"$M3CAT1\"")")
B3=$(m3 POST /supplier/businesses "$S1" "$(BJ Merkez x 40.99 KM 10 "")")
B4=$(m3 POST /supplier/businesses "$S1" "$(BJ Merkez x 40.99 KM 10 "\"$M3CATX\"")")
BOK=$(m3 POST /supplier/businesses "$S1" "$(BJ 'Kemal Tesisat Moda' 'Usta işi, 0532 123 45 67 arayın' 40.99 KM 10 "\"$M3CAT1\",\"$M3CAT2\"")"); BID=$(jget "$BOK" "d['id']")
BOK2=$(m3 POST /supplier/businesses "$S1" "$(BJ 'Kemal Tesisat Ataşehir' x 40.98 CITY null "\"$M3CAT1\"")")
[ "${B0##*|}${B1##*|}${B2##*|}${B3##*|}${B4##*|}" = "422422422422422" ] && [ "${BOK##*|}" = "201" ] && [ "${BOK2##*|}" = "201" ] \
  && ok "işletme: adsız, konumu geçersiz, yarıçap 0, kategorisiz, kapalı kategori 422; iki şube açıldı (yarıçap ve tüm il)" \
  || bad "işletme doğrulama: ad=${B0##*|} konum=${B1##*|} yarıçap=${B2##*|} kategorisiz=${B3##*|} kapalı=${B4##*|} şube1=${BOK: -60} şube2=${BOK2##*|}"
DESC=$(jget "$BOK" "d['description']"); PH=$(jget "$BOK" "d['phone']"); NC=$(jget "$BOK" "len(d['category_ids'])")
grep -q 'gizlendi' <<<"$DESC" && ! grep -q '0532' <<<"$DESC" && [ "$PH" = "+902165550011" ] && [ "$NC" = "2" ] \
  && ok "tanıtımdaki telefon gizlendi; işletme telefonu E.164'e çevrildi; iki kategori bağlandı" || bad "işletme kaydı: tanıtım=$DESC tel=$PH kategori=$NC"
NB=$(jget "$(m3 GET /supplier/businesses "$S1")" "len(d['data'])")
OB=$(m3 PUT "/supplier/businesses/$BID" "$S2" "$(BJ 'Ele geçir' x 40.99 KM 10 "\"$M3CAT1\"")")
OG=$(code "$M3/supplier/businesses/$BID" -H "$S2")
[ "$NB" = "2" ] && [ "${OB##*|}" = "404" ] && [ "$OG" = "404" ] && ok "başka tedarikçi işletmeyi göremiyor ve değiştiremiyor (404); sahibi 2 şubesini listeliyor" \
  || bad "işletme izolasyonu: liste=$NB değiştir=${OB##*|} oku=$OG"

# Hizmet kalemleri
SV0=$(m3 POST "/supplier/businesses/$BID/services" "$S1" '{"name":"Musluk değişimi","price_min_kurus":50000,"price_max_kurus":30000}')
SV1=$(m3 POST "/supplier/businesses/$BID/services" "$S1" '{"name":"Musluk değişimi","price_min_kurus":50000}')
SV2=$(m3 POST "/supplier/businesses/$BID/services" "$S1" '{"name":"Musluk değişimi","description":"e-posta usta@ornek.com","price_min_kurus":30000,"price_max_kurus":50000,"unit":"adet"}'); SID=$(jget "$SV2" "d['id']")
SV3=$(m3 POST "/supplier/businesses/$BID/services" "$S1" '{"name":"Kombi bakımı"}')
SVO=$(m3 POST "/supplier/businesses/$BID/services" "$S2" '{"name":"Başkasının"}')
[ "${SV0##*|}${SV1##*|}" = "422422" ] && [ "${SV2##*|}" = "201" ] && [ "${SV3##*|}" = "201" ] && [ "$(jget "$SV3" "d['price_min_kurus']")" = "None" ] \
  && grep -q gizlendi <<<"$(jget "$SV2" "d['description']")" && [ "${SVO##*|}" = "404" ] \
  && ok "hizmet: alt>üst 422, tek uçlu fiyat 422; aralıklı ve 'teklifle' kalem eklendi; e-posta gizlendi; başkasının işletmesine 404" \
  || bad "hizmet: alt>üst=${SV0##*|} tek uç=${SV1##*|} kayıt=${SV2: -60} teklifle=${SV3: -60} başkası=${SVO##*|}"
PU=$(curl -s -w '|%{http_code}' -X POST "$M3/supplier/services/$SID/photo" -H "$S1" -F "file=@/tmp/verify-m3-kimlik.png")
PG1=$(code "$M3/services/$SID/photo" -H "$S1"); PG2=$(code "$M3/services/$SID/photo" -H "$S2"); PG3=$(code "$M3/services/$SID/photo" -H "$MG")
[ "${PU##*|}" = "200" ] && [ "$PG1" = "200" ] && [ "$PG2$PG3" = "404404" ] \
  && ok "hizmet fotoğrafı yüklendi; sahibi görüyor; yayında olmayan işletmenin fotoğrafı başkasına ve sakine 404" \
  || bad "fotoğraf: yükle=$PU sahibi=$PG1 başka=$PG2 yönetici=$PG3"

# Durum geçişleri
BS=$(m3 POST "/supplier/businesses/$BID/submit" "$S1"); BS2=$(m3 POST "/supplier/businesses/$BID/submit" "$S1")
BC=$(m3 POST "/supplier/businesses/$(jget "$BOK2" "d['id']")/close" "$S1")
BCU=$(m3 PUT "/supplier/businesses/$(jget "$BOK2" "d['id']")" "$S1" "$(BJ 'Kapalı' x 40.99 KM 10 "\"$M3CAT1\"")")
[ "$(jget "$BS" "d['status']")" = "REVIEW" ] && [ "${BS2##*|}" = "409" ] && [ "$(jget "$BC" "d['status']")" = "CLOSED" ] && [ "${BCU##*|}" = "409" ] \
  && ok "işletme incelemeye gönderildi (ikinci kez 409); kapatılan işletme değiştirilemiyor 409" \
  || bad "işletme durumu: gönder=${BS: -40} tekrar=${BS2##*|} kapat=${BC: -40} kapalıyı değiştir=${BCU##*|}"
VP=$($PSQL -t -A -c "SELECT count(*) FROM mp_business_public WHERE account_id=(SELECT id FROM mp_supplier_accounts WHERE user_id=(SELECT id FROM users WHERE phone='+905550009201'));")
[ "$VP" = "0" ] && ok "onaylanmamış hesabın işletmeleri vitrinde yok" || bad "onaysız vitrin: $VP"
[ "$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE entity_type='marketplace' AND created_at > now() - interval '10 minutes';")" -ge 5 ] \
  && ok "pazaryeri yazma işlemleri işlem kaydında" || bad "pazaryeri işlem kaydı yok"
kill_tree "$M3I"; kill_tree "$M3M"; kill_tree "$M3G"
