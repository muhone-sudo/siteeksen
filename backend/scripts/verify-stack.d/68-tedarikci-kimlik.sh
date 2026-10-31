# shellcheck shell=bash
# verify-stack.sh tarafından `source` edilir (PSQL, IDPW, APPPW, DBPORT, J, ok/bad/step/code/kill_tree hazır).
step "68) Tedarikçi kimliği: kendi kaydı, numara ifşa etmeyen kod, mevcut hesaba rol, sitesiz giriş, platform rolü, kapsam (076, FAZ M1)"

if go test ./services/identity/service/ -count=1 -run 'SupplierSignup' >/tmp/verify-m1-unit.log 2>&1; then
  ok "go test tedarikçi kaydı sıklık sınırı (60 sn, numara saatte 3, IP saatte 10)"
else
  bad "tedarikçi kaydı sıklık sınırı birim testi"; tail -15 /tmp/verify-m1-unit.log
fi
M1DSN="postgres://siteeksen_app:$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$APPPW")@127.0.0.1:${DBPORT}/siteeksen?sslmode=disable"
if DBSCOPE_TEST_DSN="$M1DSN" go test ./pkg/dbscope/ -count=1 -v >/tmp/verify-m1-scope.log 2>&1 \
   && [ "$(grep -c -- '--- PASS' /tmp/verify-m1-scope.log)" -ge 2 ]; then
  ok "dbscope tedarikçi/platform kapsamı: boş kimlikte iş çalışmıyor, değişken transaction dışına sızmıyor (gerçek veritabanı)"
else
  bad "dbscope kapsam testleri"; tail -15 /tmp/verify-m1-scope.log
fi

rm -f /tmp/fake-netgsm.log
python3 /tmp/fake-netgsm.py 19990 >/dev/null 2>&1 &
M1NG_PID=$!
env NETGSM_USERCODE=8501112233 NETGSM_PASSWORD=api-sifre NETGSM_MSGHEADER=SITEEKSEN NETGSM_API_URL=http://127.0.0.1:19990 \
  DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_identity DB_PASSWORD="$IDPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19981 \
  go run ./services/identity >/tmp/verify-m1-identity.log 2>&1 &
M1I_PID=$!
for _ in $(seq 1 90); do curl -fsS http://127.0.0.1:19981/health >/dev/null 2>&1 && break; sleep 1; done
M1A=http://127.0.0.1:19981/api/v1/auth
m1code() { python3 -c "
import json,re,sys
rows=[json.loads(l) for l in open('/tmp/fake-netgsm.log')]
m=[r['body']['messages'][0]['msg'] for r in rows if r['body']['messages'][0]['no'].endswith(sys.argv[1])]
x=re.search(r'kayıt kodunuz: ([A-Z0-9]{8})', m[-1]) if m else None
print(x.group(1) if x else '')" "$1" 2>/dev/null; }
m1req() { curl -s -w '|%{http_code}' -X POST "$M1A/supplier-signup/request" -H "$J" -d "{\"phone\":\"$1\"}"; }
m1ver() { curl -s -w '|%{http_code}' -X POST "$M1A/supplier-signup/verify" -H "$J" -d "{\"phone\":\"$1\",\"code\":\"$2\"}"; }
m1tok() { sed -n 's/.*"signup_token":"\([^"]*\)".*/\1/p' <<<"$1"; }
m1fin() { curl -s -w '|%{http_code}' -X POST "$M1A/supplier-signup/complete" -H "$J" -d "$1"; }
m1roles() { $PSQL -t -A -c "SELECT array_to_string(roles, ',') FROM users WHERE phone='$1';"; }

# 1) Kod isteği: kayıtlı (kiracı) ve kayıtsız numaraya birebir aynı yanıt, ikisine de SMS
UC0=$($PSQL -t -A -c "SELECT count(*) FROM users;")
RQN=$(m1req "0555 000 91 01"); RQE=$(m1req "5559876543"); sleep 1
CN=$(m1code 5550009101); CE=$(m1code 5559876543)
[ "${RQN##*|}" = "200" ] && [ "$RQN" = "$RQE" ] && [ -n "$CN" ] && [ -n "$CE" ] \
  && ok "kod isteği: kayıtlı ve kayıtsız numaraya yanıt birebir aynı (numara ifşa edilmiyor), ikisine de SMS kodu gitti" \
  || bad "kod isteği: yeni=${RQN: -60} / kayıtlı=${RQE: -60} / sms yeni=$CN kayıtlı=$CE"
RQ2=$(m1req "5550009101")
[ "${RQ2##*|}" = "429" ] && ok "60 saniye dolmadan ikinci kod isteği 429 (her numara için aynı)" || bad "sıklık sınırı: $RQ2"

# 2) Yanlış kod 400; 5 yanlışta kilit
VW=$(m1ver 5550009101 AAAAAAAA)
[ "${VW##*|}" = "400" ] && ok "yanlış kod 400" || bad "yanlış kod: $VW"
m1req "5550009102" >/dev/null; sleep 1
for _ in 1 2 3 4; do m1ver 5550009102 BBBBBBBB >/dev/null; done
VL=$(m1ver 5550009102 BBBBBBBB); VL2=$(m1ver 5550009102 "$(m1code 5550009102)")
[ "${VL##*|}" = "429" ] && [ "${VL2##*|}" = "429" ] \
  && ok "5 yanlış denemede kod kilitlendi; doğru kod da artık kabul edilmiyor (429)" || bad "kod kilidi: 5.=${VL: -40} doğru=${VL2: -40}"

# 3) Yeni numara: hesap açılır, yalnız SUPPLIER; gövdedeki roles yok sayılır; jeton tek kullanımlık
VN=$(m1ver 5550009101 "$CN"); TN=$(m1tok "$VN")
grep -q '"state":"NEW"' <<<"$VN" && [ -n "$TN" ] && ok "kod doğrulanınca durum açıklandı: NEW + kayıt jetonu" || bad "doğrulama (yeni): $VN"
FN0=$(m1fin "{\"phone\":\"5550009101\",\"signup_token\":\"$TN\",\"password\":\"Esnaf2026x\",\"first_name\":\"\",\"last_name\":\"Bir\",\"terms_accepted\":true}")
FN1=$(m1fin "{\"phone\":\"5550009101\",\"signup_token\":\"$TN\",\"password\":\"Esnaf2026x\",\"first_name\":\"Usta\",\"last_name\":\"Bir\",\"terms_accepted\":false}")
FN=$(m1fin "{\"phone\":\"5550009101\",\"signup_token\":\"$TN\",\"password\":\"Esnaf2026x\",\"first_name\":\"Usta\",\"last_name\":\"Bir\",\"terms_accepted\":true,\"roles\":[\"PLATFORM_ADMIN\",\"MANAGER\"]}")
FNR=$(m1fin "{\"phone\":\"5550009101\",\"signup_token\":\"$TN\",\"password\":\"Esnaf2026x\",\"first_name\":\"Usta\",\"last_name\":\"Bir\",\"terms_accepted\":true}")
UC1=$($PSQL -t -A -c "SELECT count(*) FROM users;")
[ "${FN0##*|}" = "422" ] && [ "${FN1##*|}" = "422" ] && [ "${FN##*|}" = "200" ] && grep -q '"access_token"' <<<"$FN" \
  && [ "$(m1roles +905550009101)" = "SUPPLIER" ] && [ "${FNR##*|}" = "400" ] && [ "$UC1" = "$((UC0+1))" ] \
  && ok "yeni numara: ad/sözleşme eksikse 422; hesap açıldı, oturum verildi, rol yalnız SUPPLIER (gövdedeki roles yok sayıldı); jeton ikinci kez 400" \
  || bad "yeni hesap: adsız=${FN0##*|} sözleşmesiz=${FN1##*|} kayıt=${FN: -80} roller=$(m1roles +905550009101) tekrar=${FNR##*|} kullanıcı $UC0→$UC1"

# 4) Sitesiz giriş (M1.1): yalnız platform rolü olan hesap girer, site uçları çökmeden 403
M1TOK=$(curl -s -X POST "$M1A/login" -H "$J" -d '{"phone":"5550009101","password":"Esnaf2026x"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
ME=$(curl -s -w '|%{http_code}' "http://127.0.0.1:19981/api/v1/users/me" -H "Authorization: Bearer $M1TOK")
RS=$(code "http://127.0.0.1:19981/api/v1/residents" -H "Authorization: Bearer $M1TOK")
UN=$(code "http://127.0.0.1:19981/api/v1/units" -H "Authorization: Bearer $M1TOK")
[ -n "$M1TOK" ] && [ "${ME##*|}" = "200" ] && grep -q '"roles":\["SUPPLIER"\]' <<<"$ME" && grep -q '"active_property_id":""' <<<"$ME" \
  && [ "$RS" = "403" ] && [ "$UN" = "403" ] \
  && ok "sitesiz tedarikçi giriş yaptı (/users/me 200, roller [SUPPLIER], aktif site yok); site uçları 403 (500 değil)" \
  || bad "sitesiz giriş: jeton=$([ -n "$M1TOK" ] && echo var || echo yok) me=${ME: -120} residents=$RS units=$UN"

# 5) Kayıtlı ve etkin hesap (kiracı): yanlış şifre rol eklemez, doğru şifre ekler; yeni satır yok, sakin rolleri durur
VE=$(m1ver 5559876543 "$CE"); TE=$(m1tok "$VE")
FEW=$(m1fin "{\"phone\":\"5559876543\",\"signup_token\":\"$TE\",\"password\":\"YanlisSifre1\",\"terms_accepted\":true}")
REW=$(m1roles +905559876543)
FE=$(m1fin "{\"phone\":\"5559876543\",\"signup_token\":\"$TE\",\"password\":\"Demo123!\",\"terms_accepted\":true}")
UC2=$($PSQL -t -A -c "SELECT count(*) FROM users;")
grep -q '"state":"EXISTING"' <<<"$VE" && [ "${FEW##*|}" = "401" ] && ! grep -q SUPPLIER <<<"$REW" && [ "${FE##*|}" = "200" ] \
  && grep -q SUPPLIER <<<"$(m1roles +905559876543)" && grep -q TENANT <<<"$(m1roles +905559876543)" \
  && python3 -c "import json,sys; r=json.loads(sys.argv[1].rsplit('|',1)[0])['user']['roles']; sys.exit(0 if 'SUPPLIER' in r and 'TENANT' in r and 'RESIDENT' in r else 1)" "$FE" \
  && [ "$UC2" = "$UC1" ] \
  && ok "kayıtlı hesap: durum EXISTING; yanlış şifre 401 ve rol eklenmedi; doğru şifreyle SUPPLIER eklendi, sakin rolleri (TENANT, RESIDENT) jetonda duruyor, yeni kullanıcı satırı yok" \
  || bad "mevcut hesap: durum=${VE: -60} yanlış=${FEW##*|} roller(yanlış sonrası)=$REW doğru=${FE: -100} kullanıcı $UC1→$UC2"

# 6) Kayıtlı ama hiç etkinleştirilmemiş hesap: kodla şifre belirler, SUPPLIER eklenir
$PSQL -q -c "INSERT INTO users (first_name, last_name, phone, password_hash) VALUES ('Etkin','Değil','+905550009103','x') ON CONFLICT (phone) DO NOTHING;"
m1req "5550009103" >/dev/null; sleep 1
VI=$(m1ver 5550009103 "$(m1code 5550009103)"); TI=$(m1tok "$VI")
FI=$(m1fin "{\"phone\":\"5550009103\",\"signup_token\":\"$TI\",\"password\":\"Yeni2026sifre\",\"terms_accepted\":true}")
LI=$(code -X POST "$M1A/login" -H "$J" -d '{"phone":"5550009103","password":"Yeni2026sifre"}')
grep -q '"state":"INACTIVE"' <<<"$VI" && [ "${FI##*|}" = "200" ] && [ "$LI" = "200" ] && grep -q SUPPLIER <<<"$(m1roles +905550009103)" \
  && ok "etkinleştirilmemiş hesap: durum INACTIVE; şifre belirlendi, SUPPLIER eklendi, yeni şifreyle giriş 200" \
  || bad "etkinleştirilmemiş: durum=${VI: -60} tamamla=${FI: -80} giriş=$LI roller=$(m1roles +905550009103)"

# 7) İşlem kaydı
AE=$($PSQL -t -A -c "SELECT count(DISTINCT event) FROM audit_logs WHERE event IN ('auth.supplier_signup_request','auth.supplier_signup_verify','auth.supplier_signup_complete');")
[ "$AE" = "3" ] && ok "kayıt adımları işlem kaydında (istek, doğrulama, tamamlama)" || bad "işlem kaydı olay türü sayısı: $AE"

# 8) Platform yöneticisi rolü yalnız komutla; komut açık oturumları kapatır
PA=$(go run ./cmd/platform-admin -phone 5550009101 2>&1)
OLD=$(code "http://127.0.0.1:19981/api/v1/users/me" -H "Authorization: Bearer $M1TOK")
PTOK=$(curl -s -X POST "$M1A/login" -H "$J" -d '{"phone":"5550009101","password":"Esnaf2026x"}')
grep -q "PLATFORM_ADMIN" <<<"$PA" && [ "$OLD" = "401" ] && grep -q '"PLATFORM_ADMIN"' <<<"$PTOK" \
  && ok "platform-admin komutu PLATFORM_ADMIN verdi; eski oturum kapandı (401), yeni girişte jetonda PLATFORM_ADMIN" \
  || bad "platform-admin: $PA / eski=$OLD / yeni=${PTOK:0:200}"
go run ./cmd/platform-admin -phone 5550009101 -revoke >/dev/null 2>&1
grep -q PLATFORM_ADMIN <<<"$(m1roles +905550009101)" && bad "platform rolü geri alınamadı" || ok "platform-admin -revoke rolü geri aldı"

kill_tree "$M1I_PID"; kill "$M1NG_PID" 2>/dev/null
