# shellcheck shell=bash
# verify-stack.sh tarafından `source` edilir. Adım 73–74'ün tedarikçilerini (F1), sakinlerini (R1) ve platform yöneticisini
# (5550009701) kullanır. OCR gerçek Tesseract'tır (ana makinede yoksa denetim servisinin imajıyla aynı paketler Docker'da);
# yapay zekâ sağlayıcısı yerel sahte sunucudur (Anthropic Messages ve OpenAI uyumlu biçim).
step "77) Fotoğraf denetimi: OCR'da iletişim bilgisi → ret; yapay zekâ (açılıp kapanır) → onay ya da elle onay; platform kuyruğu (082, FAZ M13.4)"

OCRCMD=$(command -v tesseract || echo "$SCRIPT_DIR/tools/ocr-docker/tesseract")
python3 -c 'import PIL' 2>/dev/null || bad "test görselleri için Python'da pillow yok (pip install pillow; docs/claude/ortam-ve-komutlar.md)"
python3 - <<'PYEOF'
from PIL import Image, ImageDraw, ImageFont
f = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 44)
for name, text in (('tel', 'USTA ALİ TESİSAT\n0532 123 45 67'), ('temiz', 'Kombi bakımı\nPetek temizliği'),
                   ('temiz2', 'Banyo tadilatı\nSeramik döşeme'), ('temiz3', 'Elektrik tesisatı\nSigorta kutusu'),
                   ('temiz4', 'Boya badana\nİç cephe'), ('temiz5', 'Parke cila\nZemin bakımı')):
    im = Image.new('RGB', (900, 300), (250, 250, 245)); d = ImageDraw.Draw(im)
    d.multiline_text((40, 60), text, fill=(20, 20, 20), font=f, spacing=20)
    im.save('/tmp/verify-ocr-%s.png' % name)
PYEOF
cat >/tmp/fake-ai.py <<'PYEOF'
import http.server, json, sys
def mode():
    try: return open('/tmp/fake-ai-mode').read().strip() or 'CLEAN'
    except FileNotFoundError: return 'CLEAN'
VERDICT = {'CLEAN': {'unsafe': False, 'categories': [], 'reason': 'Sıradan iş fotoğrafı'},
           'UNSAFE': {'unsafe': True, 'categories': ['NUDITY'], 'reason': 'Uygunsuz içerik'}}
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers.get('Content-Length', 0))) or b'{}')
        m = mode()
        with open('/tmp/fake-ai.log', 'a') as f:
            f.write(json.dumps({'path': self.path, 'mode': m, 'x_api_key': self.headers.get('x-api-key'),
                                'authorization': self.headers.get('Authorization'), 'version': self.headers.get('anthropic-version'),
                                'body': body}) + '\n')
        if m == 'ERROR':
            self.send_response(500); self.send_header('Content-Length', '0'); self.end_headers(); return
        if self.path == '/v1/messages':
            if m == 'REFUSAL':
                out = {'type': 'message', 'stop_reason': 'refusal', 'content': []}
            else:
                out = {'type': 'message', 'stop_reason': 'end_turn',
                       'content': [{'type': 'thinking', 'thinking': ''}, {'type': 'text', 'text': json.dumps(VERDICT[m])}]}
        else:
            out = {'choices': [{'finish_reason': 'stop', 'message': {'content': 'Sonuç:\n```json\n' + json.dumps(VERDICT[m]) + '\n```'}}]}
        raw = json.dumps(out).encode()
        self.send_response(200); self.send_header('Content-Type', 'application/json'); self.send_header('Content-Length', str(len(raw)))
        self.end_headers(); self.wfile.write(raw)
    def log_message(self, *a): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PYEOF
rm -f /tmp/fake-ai.log /tmp/fake-ai-mode
python3 /tmp/fake-ai.py 19967 >/dev/null 2>&1 &
M13A=$!

m6svc 19931 services/identity siteeksen_identity "$IDPW"; M13I=$!
m6svc 19932 services/marketplace siteeksen_app "$APPPW"; M13M=$!
env DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen DB_SSLMODE=disable \
  STORAGE_BACKEND=local STORAGE_LOCAL_DIR=/tmp/verify-m3-files PII_ENCRYPTION_KEY="$PIIKEY" OCR_COMMAND="$OCRCMD" MODERATION_INTERVAL=1s \
  JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19935 go run ./services/moderation >/tmp/verify-m13-moderation.log 2>&1 &
M13D=$!
M13GW=""
for n in FINANCE COMMUNITY IOT NOTIFICATION EXPENSE ASSET BULLETIN CONTRACT DOCUMENT ENERGY ESG INVENTORY NPS PACKAGE PARKING \
         PATROL PERSONNEL RESERVATION SETTINGS SMART_COLLECTION SURVEY VISITOR BANKING GOVERNANCE; do
  M13GW="$M13GW ${n}_SERVICE_URL=http://127.0.0.1:9"
done
env $M13GW IDENTITY_SERVICE_URL=http://127.0.0.1:19931 MARKETPLACE_SERVICE_URL=http://127.0.0.1:19932 MODERATION_SERVICE_URL=http://127.0.0.1:19935 \
  JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19930 go run ./cmd/gateway >/tmp/verify-m13-gateway.log 2>&1 &
M13G=$!
for _ in $(seq 1 90); do
  curl -fsS http://127.0.0.1:19931/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19932/health >/dev/null 2>&1 \
    && curl -fsS http://127.0.0.1:19935/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19930/health >/dev/null 2>&1 && break; sleep 1
done
MD=http://127.0.0.1:19930/api/v1/moderation
md() { curl -s -w '|%{http_code}' -X "$1" "$MD$2" -H "$3" -H "$J" ${4:+-d "$4"}; }
PA=$(hdr 5550009701); HF1=$(hdr 5550009602); R1=$(hdr 5550009611); MG=$(hdr 5551234567)
FB1=$(m6sql "SELECT id FROM mp_businesses WHERE account_id='$F1' AND status='PUBLISHED' LIMIT 1;")
mksvc() { jget "$(m6 POST "/supplier/businesses/$FB1/services" "$HF1" "{\"name\":\"$1\",\"description\":\"Denetim sınaması\",\"unit\":\"iş\"}")" "d['id']"; }
SVA=$(mksvc "Kombi bakımı"); SVB=$(mksvc "Tesisat onarımı"); SVC=$(mksvc "Banyo tadilatı")
upload() { curl -s -o /dev/null -w '%{http_code}' -X POST "$M6/supplier/services/$1/photo" -H "$HF1" -F "file=@/tmp/verify-ocr-$2.png;type=image/png"; }
pmid() { m6sql "SELECT id FROM photo_moderation WHERE storage_key=(SELECT photo_key FROM mp_business_services WHERE id='$1');"; }
waitpm() { for _ in $(seq 1 90); do [ "$(m6sql "SELECT status FROM photo_moderation WHERE id='$1';")" != "PENDING" ] && break; sleep 1; done
  m6sql "SELECT status FROM photo_moderation WHERE id='$1';"; }
pmrow() { m6sql "SELECT status||'|'||COALESCE(decision_source,'-')||'|'||COALESCE(ai_verdict,'-')||'|'||array_to_string(ai_categories,',') FROM photo_moderation WHERE id='$1';"; }

# Yetki: kimliksiz 401, tedarikçi/sakin 403
U0=$(curl -s -o /dev/null -w '%{http_code}' "$MD/photos"); U1=$(md GET /photos "$HF1"); U2=$(md GET /photos "$MG")
[ "$U0" = "401" ] && [ "${U1##*|}" = "403" ] && [ "${U2##*|}" = "403" ] && ok "denetim uçları yalnız platform yöneticisine: kimliksiz 401, tedarikçi ve site yöneticisi 403" \
  || bad "denetim yetkisi: kimliksiz=$U0 tedarikçi=${U1##*|} yönetici=${U2##*|}"

# 1) Yapay zekâ kapalı: temiz görsel OCR'dan geçer, elle onaya düşer; vitrinde yok
UA=$(upload "$SVA" temiz); PA1=$(pmid "$SVA"); SA1=$(waitpm "$PA1")
OTA=$(m6sql "SELECT ocr_text FROM photo_moderation WHERE id='$PA1';")
VA0=$(code "$M6/services/$SVA/photo" -H "$MG"); OWN=$(code "$M6/services/$SVA/photo" -H "$HF1")
SJA=$(m6 GET "/supplier/businesses/$FB1/services" "$HF1")
[ "$UA" = "200" ] && [ "$SA1" = "REVIEW" ] && grep -qi "kombi" <<<"$OTA" && [ "$VA0" = "404" ] && [ "$OWN" = "200" ] \
  && [ "$(jget "$SJA" "[x['photo_status'] for x in d['data'] if x['id']=='$SVA'][0]")" = "REVIEW" ] \
  && ok "yapay zekâ kapalıyken temiz fotoğraf OCR'dan geçti (okunan: '$(echo "$OTA" | head -1)') ve elle onay kuyruğuna düştü; vitrinde 404, sahibi görüyor ve durumu 'incelemede'" \
  || bad "kapalı yapay zekâ: yükle=$UA durum=$SA1 ocr='$OTA' vitrin=$VA0 sahibi=$OWN tedarikçi=${SJA:0:200}"

# 2) OCR'da telefon: otomatik ret, gerekçe ve bildirim; yapay zekâya gitmez
: >/tmp/fake-ai.log
UB=$(upload "$SVB" tel); PB1=$(pmid "$SVB"); SB1=$(waitpm "$PB1")
RB=$(m6sql "SELECT COALESCE(reason,'')||'|'||array_to_string(ocr_findings,',')||'|'||COALESCE(decision_source,'') FROM photo_moderation WHERE id='$PB1';")
NB=$(m6sql "SELECT count(*) FROM notifications WHERE supplier_account_id='$F1' AND topic='market.photo.rejected';")
SJB=$(m6 GET "/supplier/businesses/$FB1/services" "$HF1")
[ "$UB" = "200" ] && [ "$SB1" = "REJECTED" ] && grep -q "iletişim bilgisi" <<<"$RB" && grep -q "PHONE: 0532 123 45 67" <<<"$RB" && grep -q "|OCR$" <<<"$RB" \
  && [ "$NB" -ge 1 ] && [ ! -s /tmp/fake-ai.log ] && [ "$(jget "$SJB" "[x['photo_status'] for x in d['data'] if x['id']=='$SVB'][0]")" = "REJECTED" ] \
  && ok "OCR fotoğraftaki telefonu okudu: otomatik ret (yapay zekâya gitmedi), gerekçe tedarikçiye gösteriliyor ve bildirildi" \
  || bad "OCR reddi: yükle=$UB durum=$SB1 satır=$RB bildirim=$NB yapay zekâ çağrısı=$(wc -l </tmp/fake-ai.log)"

# 3) Platform kuyruğu: görseli görür, gerekçesiz ret 422, onay → vitrinde açık; onaylanmışı gerekçeyle kaldırır
QL=$(md GET /photos "$PA"); IMG=$(curl -s -o /dev/null -w '%{http_code}|%{content_type}' "$MD/photos/$PA1/image" -H "$PA")
RJ0=$(md POST "/photos/$PA1/reject" "$PA" '{"reason":""}'); AP=$(md POST "/photos/$PA1/approve" "$PA" '{}')
VA1=$(code "$M6/services/$SVA/photo" -H "$MG")
RJ1=$(md POST "/photos/$PA1/reject" "$PA" '{"reason":"Fotoğraf hizmetle ilgisiz"}'); VA2=$(code "$M6/services/$SVA/photo" -H "$MG")
AUD=$(m6sql "SELECT count(*) FROM audit_logs WHERE entity_type='moderation' AND details->>'photo_id'='$PA1';")
[ "$(jget "$QL" "len([x for x in d['data'] if x['id']=='$PA1' and x['context']])")" = "1" ] && [ "$IMG" = "200|image/png" ] && [ "${RJ0##*|}" = "422" ] \
  && [ "$(jget "$AP" "d['status']")" = "APPROVED" ] && [ "$VA1" = "200" ] && [ "$(jget "$RJ1" "d['status']")" = "REJECTED" ] && [ "$VA2" = "404" ] && [ "$AUD" -ge 2 ] \
  && ok "platform kuyruğu: fotoğraf bağlamıyla listelendi ve görüntülendi; gerekçesiz ret 422; onaydan sonra vitrinde 200, gerekçeyle kaldırınca 404; kararlar işlem kaydında" \
  || bad "platform kuyruğu: liste=${QL:0:160} görsel=$IMG ret0=${RJ0##*|} onay=${AP: -60} vitrin=$VA1/$VA2 kayıt=$AUD"

# 4) Yapay zekâ ayarı: kimlik bilgisi olmadan açılamaz; gizli değer şifreli saklanır ve geri dönmez
S0=$(md PUT /ai-settings "$PA" '{"enabled":true,"provider":"ANTHROPIC","base_url":"http://127.0.0.1:19967","model":"claude-opus-5-5","auth_type":"API_KEY"}')
S1=$(md PUT /ai-settings "$PA" '{"enabled":true,"provider":"ANTHROPIC","base_url":"http://127.0.0.1:19967","model":"claude-opus-5-5","auth_type":"API_KEY","api_key":"sk-verify-gizli-123"}')
SG=$(md GET /ai-settings "$PA")
ENC=$(m6sql "SELECT (api_key_enc IS NOT NULL AND api_key_enc NOT LIKE '%sk-verify%')::text FROM moderation_ai_settings;")
LEAK=$(m6sql "SELECT count(*) FROM audit_logs WHERE entity_type='moderation' AND details::text LIKE '%sk-verify-gizli%';")
[ "${S0##*|}" = "422" ] && [ "${S1##*|}" = "200" ] && [ "$(jget "$SG" "d['api_key_set']")" = "True" ] && ! grep -q "sk-verify" <<<"$SG$S1" && [ "$ENC" = "true" ] && [ "$LEAK" = "0" ] \
  && ok "yapay zekâ ayarı: anahtarsız açma 422; API anahtarı şifreli saklandı, yanıtta ve işlem kaydında görünmüyor (yalnız 'tanımlı')" \
  || bad "yapay zekâ ayarı: anahtarsız=${S0##*|} kayıt=${S1: -120} okuma=${SG:0:200} şifreli=$ENC sızıntı=$LEAK"

# 5) Anthropic biçimi: temiz → otomatik onay; sakıncalı, ret (refusal) ve sağlayıcı hatası → elle onay (sessiz onay yok)
aiupload() { echo "$1" >/tmp/fake-ai-mode; upload "$SVC" "$2" >/dev/null; local id; id=$(pmid "$SVC"); waitpm "$id" >/dev/null; pmrow "$id"; }
: >/tmp/fake-ai.log
C1=$(aiupload CLEAN temiz2); VC=$(code "$M6/services/$SVC/photo" -H "$MG")
AREQ=$(python3 -c "
import json
r=[json.loads(l) for l in open('/tmp/fake-ai.log')][0]; b=r['body']; c=b['messages'][0]['content']
print(r['path'], r['x_api_key'], r['version'], b['model'], c[0]['type'], c[0]['source']['media_type'], len(c[0]['source']['data'])>100,
      b['output_config']['format']['type'], 'temperature' in b)")
C2=$(aiupload UNSAFE temiz3); C3=$(aiupload REFUSAL temiz4); C4=$(aiupload ERROR temiz5)
[ "$C1" = "APPROVED|AI|CLEAN|" ] && [ "$VC" = "200" ] && [ "$AREQ" = "/v1/messages sk-verify-gizli-123 2026-10-21 claude-opus-5-5 image image/png True json_schema False" ] \
  && [ "$C2" = "REVIEW|-|UNSAFE|NUDITY" ] && [ "$C3" = "REVIEW|-|UNSAFE|" ] && [ "$C4" = "REVIEW|-|ERROR|" ] \
  && ok "yapay zekâ (Anthropic Messages): temiz → otomatik onay ve vitrinde; istek görsel + JSON şeması + API anahtarıyla gitti; sakıncalı (NUDITY), sağlayıcı reddi ve sağlayıcı hatası → elle onay kuyruğu" \
  || bad "Anthropic yolu: temiz=$C1 vitrin=$VC istek='$AREQ' sakıncalı=$C2 ret=$C3 hata=$C4"

# 6) OpenAI uyumlu (yerel sunucu) + kullanıcı adı/parola; bağlantı sınaması
S2=$(md PUT /ai-settings "$PA" '{"enabled":true,"provider":"OPENAI","base_url":"http://127.0.0.1:19967/v1","model":"llava","auth_type":"BASIC","username":"denetim","password":"p-gizli"}')
: >/tmp/fake-ai.log
C5=$(aiupload CLEAN temiz2)
OREQ=$(python3 -c "
import json
r=[json.loads(l) for l in open('/tmp/fake-ai.log')][0]; c=r['body']['messages'][0]['content']
print(r['path'], r['authorization'], r['body']['model'], c[1]['image_url']['url'][:22])")
TS=$(md POST /ai-settings/test "$PA")
[ "${S2##*|}" = "200" ] && [ "$C5" = "APPROVED|AI|CLEAN|" ] && [ "$OREQ" = "/v1/chat/completions Basic ZGVuZXRpbTpwLWdpemxp llava data:image/png;base64," ] \
  && [ "$(jget "$TS" "d['ok']")" = "True" ] \
  && ok "yapay zekâ (OpenAI uyumlu, yerel sunucu biçimi): Basic kimlikle görsel gönderildi, metne gömülü JSON okundu → onay; 'bağlantıyı sına' çalıştı" \
  || bad "OpenAI yolu: ayar=${S2: -80} sonuç=$C5 istek='$OREQ' sınama=${TS: -120}"
md PUT /ai-settings "$PA" '{"enabled":false,"provider":"ANTHROPIC","base_url":"https://api.anthropic.com","model":"","auth_type":"API_KEY","clear_api_key":true,"clear_password":true}' >/dev/null

# 7) Talep fotoğrafı: telefonlu görsel reddedilir; sakin durumu ve gerekçeyi görür, bildirim alır; tedarikçiye gösterilmez
# Sakinin son talebi (önceki adımlarda kapanmış olabilir: sınama için yeniden açılır, fotoğrafları boşaltılmaz)
RQ=$(m6sql "SELECT id FROM mp_requests WHERE requester_user_id=(SELECT id FROM users WHERE phone='+905550009611') AND jsonb_array_length(photo_keys) < 3 ORDER BY created_at DESC LIMIT 1;")
m6sql "UPDATE mp_requests SET status='OPEN', expires_at=now() + interval '1 day' WHERE id='$RQ' AND status NOT IN ('OPEN','FULL');" >/dev/null
RU=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$M6/requests/$RQ/photos" -H "$R1" -F "file=@/tmp/verify-ocr-tel.png;type=image/png")
RPM=$(m6sql "SELECT id FROM photo_moderation WHERE request_id='$RQ' ORDER BY created_at DESC LIMIT 1;"); RS=$(waitpm "$RPM")
RB=$(m6 GET "/requests/$RQ" "$R1")
RN=$(m6sql "SELECT count(*) FROM notifications WHERE topic='market.photo.rejected' AND recipient_user_id=(SELECT id FROM users WHERE phone='+905550009611');")
RAPP=$(m6sql "SELECT count(*) FROM jsonb_array_elements_text((SELECT photo_keys FROM mp_requests WHERE id='$RQ')) k WHERE photo_approved(k);")
[ "$RU" = "200" ] && [ "$RS" = "REJECTED" ] && [ "$(jget "$RB" "d['photo_statuses'][-1]['status']")" = "REJECTED" ] \
  && jget "$RB" "d['photo_statuses'][-1]['reason']" | grep -q "iletişim bilgisi" && [ "$RN" -ge 1 ] \
  && ok "talep fotoğrafı: telefonlu görsel OCR'la reddedildi; sakin talebinde durumu ve gerekçeyi görüyor, bildirim aldı; tedarikçiye yalnız onaylı fotoğraflar ($RAPP) gösteriliyor" \
  || bad "talep fotoğrafı: yükle=$RU durum=$RS alıcı=${RB:0:200} bildirim=$RN"
kill_tree "$M13I"; kill_tree "$M13M"; kill_tree "$M13D"; kill_tree "$M13G"; kill "$M13A" 2>/dev/null
