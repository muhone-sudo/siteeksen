#!/usr/bin/env python3
"""Tarayıcı testi için yerel yardımcı sunucu (yalnız geliştirme; 127.0.0.1).

  /                 araç listesi
  /sms              sahte Netgsm'e gelen SMS'ler   (servisler NETGSM_API_URL=…/netgsm ile buraya yollar)
  /iyzico/…         sahte iyzico API'si (IYZWSv2 imzasını doğrular) + /iyzico/pay/<jeton> ödeme sayfası
  /odeme-sonuc      kart ödemesi sonrası dönüş sayfası (PAYMENT_RESULT_URL)
  /cihaz            sensör okuması ve geçiş cihazı sinyali gönderme (X-Device-Key)
  /gunluk?s=<ad>    servis günlüğünün son satırları (/tmp/dev-<ad>.log)
  /sifirla?k=sms    SMS listesini temizler
  /sonuc            test sonucu kaydı (ID, durum, gözlem); /sonuc.json, /sonuc.md dışa aktarım

Kullanım: python3 sunucu.py <port> <gateway-url> <veri-dizini> <sonuç-dosyası>
"""
import base64, hashlib, hmac, html, json, os, sys, threading, time, urllib.parse, urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT, GATEWAY, DATA, RESULTS = int(sys.argv[1]), sys.argv[2].rstrip("/"), sys.argv[3], sys.argv[4]
os.makedirs(DATA, exist_ok=True)
os.makedirs(os.path.dirname(RESULTS), exist_ok=True)
STATES = ["GEÇTİ", "KALDI", "KISMEN", "ATLANDI", "ENGELLENDİ"]
SMS_LOG, IYZ_LOG, DEV_LOG = (os.path.join(DATA, n) for n in ("sms.jsonl", "iyzico.jsonl", "cihaz.jsonl"))
IYZ_KEY, IYZ_SECRET = "sandbox-ak", b"sandbox-sk"
CALLBACK = GATEWAY + "/api/v1/public/payments/iyzico/callback"
LOCK = threading.Lock()
TOKENS = {}  # jeton → {basketId, price, n, mode, callback}
SERVICES = ["gateway", "identity", "finance", "community", "iot", "notification", "expense", "asset", "bulletin",
            "contract", "document", "energy", "esg", "inventory", "nps", "package", "parking", "patrol", "personnel",
            "reservation", "settings", "collection", "survey", "visitor", "governance", "scheduler"]


def now():
    return time.strftime("%Y-%m-%d %H:%M:%S")


def append(path, rec):
    with LOCK, open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")


def read(path):
    try:
        with open(path, encoding="utf-8") as f:
            return [json.loads(l) for l in f if l.strip()]
    except FileNotFoundError:
        return []


def page(title, body):
    return ("<!doctype html><html lang=tr><head><meta charset=utf-8><title>%s</title>"
            "<meta name=viewport content='width=device-width,initial-scale=1'>"
            "<style>body{font:15px system-ui,sans-serif;margin:24px;max-width:1100px;color:#111}"
            "table{border-collapse:collapse;width:100%%}td,th{border:1px solid #ccc;padding:6px 8px;text-align:left;vertical-align:top}"
            "th{background:#f3f3f3}code,pre{background:#f6f6f6;padding:2px 4px;white-space:pre-wrap;word-break:break-all}"
            "button{font-size:15px;padding:8px 14px;margin:4px 6px 4px 0;cursor:pointer}input,select{font-size:15px;padding:6px;margin:4px 0}"
            "a{color:#0645ad}.ok{color:#080}.bad{color:#b00}nav a{margin-right:14px}</style></head><body>"
            "<nav><a href=/>Araçlar</a><a href=/sms>SMS kutusu</a><a href=/iyzico>iyzico kayıtları</a>"
            "<a href=/cihaz>Cihaz simülatörü</a><a href=/gunluk>Servis günlükleri</a><a href=/sonuc>Test sonuçları</a></nav><h1>%s</h1>%s</body></html>"
            % (html.escape(title), html.escape(title), body))


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def send(self, code, body, ctype="text/html; charset=utf-8"):
        raw = body.encode() if isinstance(body, str) else body
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(raw)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(raw)

    def body(self):
        return self.rfile.read(int(self.headers.get("Content-Length", 0) or 0))

    # ---------------- GET ----------------
    def do_GET(self):
        u = urllib.parse.urlparse(self.path)
        q = urllib.parse.parse_qs(u.query)
        p = u.path
        if p == "/":
            return self.send(200, page("SiteEksen test araçları", INDEX))
        if p == "/sms":
            return self.send(200, page("SMS kutusu (sahte Netgsm)", sms_table()))
        if p == "/sms.json":
            return self.send(200, json.dumps(read(SMS_LOG), ensure_ascii=False), "application/json")
        if p == "/iyzico":
            rows = "".join("<tr><td>%s</td><td><code>%s</code></td><td>%s</td><td><pre>%s</pre></td></tr>" % (
                html.escape(r["t"]), html.escape(r["path"]), "geçerli" if r["sig_ok"] else "<b class=bad>GEÇERSİZ</b>",
                html.escape(json.dumps(r["body"], ensure_ascii=False, indent=1))) for r in reversed(read(IYZ_LOG)))
            return self.send(200, page("iyzico kayıtları (sahte)", "<p>Finans servisinin sahte iyzico'ya yaptığı her çağrı. "
                                       "İmza (IYZWSv2) burada doğrulanır.</p><table><tr><th>Zaman</th><th>Uç</th><th>İmza</th><th>Gövde</th></tr>%s</table>" % rows))
        if p.startswith("/iyzico/pay/"):
            return self.pay_page(p.rsplit("/", 1)[1])
        if p == "/odeme-sonuc":
            items = "".join("<tr><th>%s</th><td>%s</td></tr>" % (html.escape(k), html.escape(", ".join(v))) for k, v in q.items())
            return self.send(200, page("Kart ödemesi sonucu", "<p>Finans servisi iyzico dönüşünü işledi ve tarayıcıyı buraya yönlendirdi. "
                                       "Uygulamaya dönüp ödeme durumunu yenileyin.</p><table>%s</table>" % (items or "<tr><td>parametre yok</td></tr>")))
        if p == "/cihaz":
            return self.send(200, page("Cihaz simülatörü", device_form(q.get("sonuc", [""])[0])))
        if p == "/gunluk":
            s = q.get("s", [""])[0]
            if s not in SERVICES:
                links = " ".join("<a href='/gunluk?s=%s'>%s</a>" % (x, x) for x in SERVICES)
                return self.send(200, page("Servis günlükleri", "<p>%s</p>" % links))
            n = int(q.get("n", ["200"])[0])
            try:
                with open("/tmp/dev-%s.log" % s, encoding="utf-8", errors="replace") as f:
                    lines = f.readlines()[-n:]
            except FileNotFoundError:
                lines = ["(günlük yok)"]
            return self.send(200, page("Günlük: " + s, "<p><a href='/gunluk'>tümü</a> · son %d satır</p><pre>%s</pre>" % (n, html.escape("".join(lines)))))
        if p == "/sonuc":
            return self.send(200, page("Test sonuçları", results_page(q.get("bolum", [""])[0])))
        if p == "/sonuc.json":
            return self.send(200, json.dumps(latest_results(), ensure_ascii=False, indent=1), "application/json")
        if p == "/sonuc.md":
            lines = ["| ID | Durum | Hesap | Gözlem | Zaman |", "|---|---|---|---|---|"]
            for r in latest_results():
                lines.append("| %s | %s | %s | %s | %s |" % tuple(str(r.get(k, "")).replace("|", "/").replace("\n", " ") for k in ("id", "durum", "hesap", "gozlem", "t")))
            return self.send(200, "\n".join(lines) + "\n", "text/markdown; charset=utf-8")
        if p == "/sifirla":
            if q.get("k", [""])[0] == "sms":
                with LOCK:
                    open(SMS_LOG, "w").close()
            return self.redirect("/sms")
        self.send(404, page("Bulunamadı", "<p>%s</p>" % html.escape(p)))

    def redirect(self, to):
        self.send_response(303)
        self.send_header("Location", to)
        self.end_headers()

    # ---------------- POST ----------------
    def do_POST(self):
        p = urllib.parse.urlparse(self.path).path
        raw = self.body()
        if p.startswith("/netgsm"):
            return self.netgsm(p, raw)
        if p.startswith("/iyzico/pay/"):
            return self.pay_submit(p.rsplit("/", 1)[1], raw)
        if p.startswith("/iyzico/"):
            return self.iyzico(p[len("/iyzico"):], raw)
        if p == "/cihaz":
            return self.device(raw)
        if p == "/sonuc":
            f = {k: v[0] for k, v in urllib.parse.parse_qs(raw.decode()).items()}
            ids = [x.strip() for x in f.get("id", "").replace(",", " ").split() if x.strip()]
            if not ids or f.get("durum") not in STATES:
                return self.send(400, page("Test sonuçları", "<p class=bad>ID ve geçerli bir durum zorunlu.</p><p><a href=/sonuc>geri</a></p>"))
            for i in ids:
                append(RESULTS, {"t": now(), "id": i, "durum": f["durum"], "hesap": f.get("hesap", ""), "gozlem": f.get("gozlem", "")})
            return self.redirect("/sonuc?bolum=" + urllib.parse.quote(ids[0].split("-")[0]))
        self.send(404, "{}", "application/json")

    def netgsm(self, path, raw):
        auth = base64.b64decode(self.headers.get("Authorization", "Basic ")[6:] or b"").decode(errors="replace")
        try:
            body = json.loads(raw or b"{}")
        except ValueError:
            body = {"ham": raw.decode(errors="replace")}
        append(SMS_LOG, {"t": now(), "path": path, "user": auth.split(":", 1)[0], "body": body})
        self.send(200, '{"code":"00","jobid":"TEST-%d"}' % int(time.time() * 1000), "application/json")

    def iyzico(self, path, raw):
        rnd = self.headers.get("x-iyzi-rnd", "")
        auth = base64.b64decode(self.headers.get("Authorization", "IYZWSv2 ")[8:] or b"").decode(errors="replace")
        parts = dict(x.split(":", 1) for x in auth.split("&") if ":" in x)
        sig = hmac.new(IYZ_SECRET, (rnd + path).encode() + raw, hashlib.sha256).hexdigest()
        ok = parts.get("apiKey") == IYZ_KEY and parts.get("randomKey") == rnd and hmac.compare_digest(parts.get("signature", ""), sig)
        req = json.loads(raw or b"{}")
        append(IYZ_LOG, {"t": now(), "path": path, "sig_ok": ok, "body": req})
        if not ok:
            out = {"status": "failure", "errorCode": "1001", "errorMessage": "imza geçersiz"}
        elif path.endswith("/initialize/auth/ecom"):
            with LOCK:
                n = len(TOKENS) + 1
                tok = "test-%d-%d" % (n, int(time.time()))
                TOKENS[tok] = {"basketId": req.get("basketId"), "price": req.get("paidPrice"), "n": n, "mode": "INIT",
                               "callback": req.get("callbackUrl") or CALLBACK}
            out = {"status": "success", "token": tok, "paymentPageUrl": "http://localhost:%d/iyzico/pay/%s" % (PORT, tok),
                   "tokenExpireTime": 1800}
        else:
            t = TOKENS.get(req.get("token"))
            if t is None:
                out = {"status": "failure", "errorCode": "5139", "errorMessage": "Jeton bulunamadı"}
            elif t["mode"] == "SUCCESS":
                out = {"status": "success", "paymentStatus": "SUCCESS", "paymentId": "TESTPAY-%d" % t["n"],
                       "paidPrice": t["price"], "basketId": t["basketId"]}
            elif t["mode"] == "INIT":
                out = {"status": "success", "paymentStatus": "INIT_THREEDS", "basketId": t["basketId"]}
            else:
                code, msg = t["mode"].split(":", 1)
                out = {"status": "success", "paymentStatus": "FAILURE", "errorCode": code, "errorMessage": msg, "basketId": t["basketId"]}
        self.send(200, json.dumps(out, ensure_ascii=False), "application/json")

    def pay_page(self, tok):
        t = TOKENS.get(tok)
        if not t:
            return self.send(404, page("Ödeme sayfası", "<p class=bad>Jeton bulunamadı (sunucu yeniden başlatıldıysa ödemeyi yeniden başlatın).</p>"))
        body = ("<p>Bu sayfa iyzico'nun ödeme formunun yerine geçer. Gerçek kart bilgisi istenmez.</p>"
                "<table><tr><th>Jeton</th><td><code>%s</code></td></tr><tr><th>Sepet</th><td><code>%s</code></td></tr>"
                "<tr><th>Tutar</th><td><b>%s TL</b></td></tr><tr><th>Durum</th><td>%s</td></tr></table>"
                "<form method=post><p>Sonucu seçin:</p>"
                "<button name=sonuc value=SUCCESS>Ödeme başarılı</button>"
                "<button name=sonuc value='10051:Kart limiti yetersiz'>Reddedildi: limit yetersiz</button>"
                "<button name=sonuc value='10005:İşlem onaylanmadı'>Reddedildi: banka onaylamadı</button>"
                "<button name=sonuc value=INIT>Yarıda bırak (3D doğrulama bitmedi)</button></form>"
                % (html.escape(tok), html.escape(str(t["basketId"])), html.escape(str(t["price"])), html.escape(t["mode"])))
        self.send(200, page("Sahte iyzico ödeme sayfası", body))

    def pay_submit(self, tok, raw):
        t = TOKENS.get(tok)
        if not t:
            return self.send(404, page("Ödeme sayfası", "<p class=bad>Jeton bulunamadı.</p>"))
        mode = urllib.parse.parse_qs(raw.decode()).get("sonuc", ["SUCCESS"])[0]
        t["mode"] = mode
        body = ("<p>Seçilen sonuç: <b>%s</b>. Tarayıcı iyzico'nun yaptığı gibi ödemeyi başlatan servisin geri dönüş adresine gönderiliyor…</p>"
                "<form id=f method=post action='%s'><input type=hidden name=token value='%s'>"
                "<button>Devam et</button></form><script>document.getElementById('f').submit()</script>"
                % (html.escape(mode), html.escape(t["callback"]), html.escape(tok)))
        self.send(200, page("Geri dönüş", body))

    def device(self, raw):
        f = {k: v[0] for k, v in urllib.parse.parse_qs(raw.decode()).items()}
        kind, key = f.get("tur", "sensor"), f.get("anahtar", "").strip()
        if kind == "sensor":
            url, payload = GATEWAY + "/api/v1/public/sensors/data", {"value": float(f.get("deger", "0") or 0)}
            if f.get("zaman"):
                payload["recorded_at"] = f["zaman"]
        else:
            url, payload = GATEWAY + "/api/v1/public/devices/heartbeat", {"status": f.get("durum", "OK")}
        req = urllib.request.Request(url, data=json.dumps(payload).encode(), method="POST",
                                     headers={"Content-Type": "application/json", "X-Device-Key": key})
        try:
            with urllib.request.urlopen(req, timeout=15) as r:
                code, text = r.status, r.read().decode(errors="replace")
        except urllib.error.HTTPError as e:
            code, text = e.code, e.read().decode(errors="replace")
        except OSError as e:
            code, text = 0, str(e)
        append(DEV_LOG, {"t": now(), "tur": kind, "anahtar": key[:6] + "…", "gonderilen": payload, "kod": code, "yanit": text})
        self.redirect("/cihaz?sonuc=1")


def latest_results():
    last = {}
    for r in read(RESULTS):
        last[r["id"]] = r
    return sorted(last.values(), key=lambda r: r["id"])


def results_page(prefix):
    rs = latest_results()
    counts = {s: sum(1 for r in rs if r["durum"] == s) for s in STATES}
    shown = [r for r in rs if not prefix or r["id"].startswith(prefix)]
    rows = "".join("<tr><td><code>%s</code></td><td class=%s>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>" % (
        html.escape(r["id"]), "ok" if r["durum"] == "GEÇTİ" else "bad" if r["durum"] in ("KALDI", "KISMEN") else "",
        html.escape(r["durum"]), html.escape(r.get("hesap", "")), html.escape(r.get("gozlem", "")), html.escape(r["t"])) for r in reversed(shown))
    opts = "".join("<option>%s</option>" % s for s in STATES)
    return ("<p>Her test adımının sonucunu buraya kaydedin. Aynı ID yeniden kaydedilirse son kayıt geçerlidir; geçmiş silinmez. "
            "Birden çok ID'yi boşlukla ayırarak aynı sonuçla kaydedebilirsiniz. "
            "Kayıtlar ortam yeniden başlatılsa da kalır (%s).</p>"
            "<form method=post><table>"
            "<tr><th>Test ID</th><td><input name=id size=40 required placeholder='P-SAKINLER-03'></td></tr>"
            "<tr><th>Durum</th><td><select name=durum>%s</select> "
            "GEÇTİ: beklenenin tamamı oldu · KALDI: beklenen olmadı/hata · KISMEN: bir kısmı oldu · ATLANDI: koşul sağlanamadı · ENGELLENDİ: önceki bir hata yüzünden denenemedi</td></tr>"
            "<tr><th>Hesap</th><td><input name=hesap size=20 placeholder='YÖNETİCİ'></td></tr>"
            "<tr><th>Gözlem</th><td><textarea name=gozlem rows=4 cols=90 placeholder='Ne yapıldı, ne görüldü; hata metni, beklenenden fark'></textarea></td></tr>"
            "</table><button>Kaydet</button></form>"
            "<p>Toplam %d test · %s · <a href=/sonuc.md>Markdown</a> · <a href=/sonuc.json>JSON</a></p>"
            "<table><tr><th>ID</th><th>Durum</th><th>Hesap</th><th>Gözlem</th><th>Zaman</th></tr>%s</table>"
            % (html.escape(RESULTS), opts, len(rs), " · ".join("%s %d" % (k, v) for k, v in counts.items()), rows or "<tr><td colspan=5>Kayıt yok</td></tr>"))


def sms_table():
    rows = []
    for r in reversed(read(SMS_LOG)):
        msgs = r["body"].get("messages") if isinstance(r["body"], dict) else None
        for m in msgs or [{"no": "?", "msg": json.dumps(r["body"], ensure_ascii=False)}]:
            rows.append("<tr><td>%s</td><td><b>%s</b></td><td>%s</td><td>%s</td></tr>" % (
                html.escape(r["t"]), html.escape(str(m.get("no", ""))), html.escape(str(m.get("msg", ""))),
                html.escape(str(r["body"].get("msgheader", "")) if isinstance(r["body"], dict) else "")))
    return ("<p>Servislerin gönderdiği her SMS burada görünür (en yeni üstte). Numara Netgsm biçimindedir (5XXXXXXXXX). "
            "<a href='/sifirla?k=sms'>Listeyi temizle</a> · <a href=/sms.json>JSON</a></p>"
            "<table><tr><th>Zaman</th><th>Numara</th><th>Metin</th><th>Başlık</th></tr>%s</table>"
            % ("".join(rows) or "<tr><td colspan=4>Henüz SMS yok</td></tr>"))


def device_form(show):
    last = read(DEV_LOG)[-15:]
    rows = "".join("<tr><td>%s</td><td>%s</td><td><code>%s</code></td><td><code>%s</code></td><td class=%s>%s</td><td><code>%s</code></td></tr>" % (
        html.escape(r["t"]), html.escape(r["tur"]), html.escape(r["anahtar"]), html.escape(json.dumps(r["gonderilen"])),
        "ok" if 200 <= r["kod"] < 300 else "bad", r["kod"], html.escape(r["yanit"][:300])) for r in reversed(last))
    return ("<p>Sensör ve geçiş cihazı oturum açmaz; kendi anahtarıyla (<code>X-Device-Key</code>) kimliksiz uca yazar. "
            "Anahtar, panelde sensör/cihaz eklendiğinde ya da anahtar yenilendiğinde <b>bir kez</b> gösterilir.</p>"
            "<form method=post><table>"
            "<tr><th>Tür</th><td><select name=tur><option value=sensor>Sensör okuması (POST /public/sensors/data)</option>"
            "<option value=cihaz>Geçiş cihazı sinyali (POST /public/devices/heartbeat)</option></select></td></tr>"
            "<tr><th>Cihaz anahtarı</th><td><input name=anahtar size=70 required></td></tr>"
            "<tr><th>Değer (sensör)</th><td><input name=deger value='25'> ikili sensörde 1 = tetiklendi, 0 = normal</td></tr>"
            "<tr><th>Ölçüm zamanı (isteğe bağlı)</th><td><input name=zaman placeholder='2026-10-28T10:00:00+03:00' size=30></td></tr>"
            "<tr><th>Durum (geçiş cihazı)</th><td><input name=durum value='OK'></td></tr>"
            "</table><button>Gönder</button></form>"
            "<h2>Son gönderimler</h2><table><tr><th>Zaman</th><th>Tür</th><th>Anahtar</th><th>Gönderilen</th><th>HTTP</th><th>Yanıt</th></tr>%s</table>"
            % (rows or "<tr><td colspan=6>Henüz gönderim yok</td></tr>"))


INDEX = """
<table>
<tr><th>Ne</th><th>Adres</th><th>Not</th></tr>
<tr><td>Yönetim paneli</td><td><a href="http://localhost:3001">http://localhost:3001</a></td><td>Next.js</td></tr>
<tr><td>Sakin uygulaması (web derlemesi)</td><td><a href="http://localhost:3002">http://localhost:3002</a></td><td>Flutter web; telefon genişliğinde kullanın</td></tr>
<tr><td>Yönetici uygulaması (web derlemesi)</td><td><a href="http://localhost:3003">http://localhost:3003</a></td><td>Flutter web</td></tr>
<tr><td>Veritabanı (Adminer, salt okunur)</td><td><a href="http://localhost:18080">http://localhost:18080</a></td><td>PostgreSQL · sunucu <code>db</code> · kullanıcı <code>test_okuyucu</code> · şifre <code>test_okuyucu</code> · veritabanı <code>siteeksen</code></td></tr>
<tr><td>E-posta kutusu (Mailpit)</td><td><a href="http://localhost:18025">http://localhost:18025</a></td><td>Servislerin gönderdiği bütün e-postalar</td></tr>
<tr><td>SMS kutusu</td><td><a href="/sms">/sms</a></td><td>Sahte Netgsm</td></tr>
<tr><td>Kart ödemesi</td><td><a href="/iyzico">/iyzico</a></td><td>Sahte iyzico; ödeme sayfası ödeme başlatılınca açılır</td></tr>
<tr><td>Cihaz simülatörü</td><td><a href="/cihaz">/cihaz</a></td><td>Sensör okuması, geçiş cihazı sinyali</td></tr>
<tr><td>Servis günlükleri</td><td><a href="/gunluk">/gunluk</a></td><td>Hata ayıklama için</td></tr>
<tr><td><b>Test sonuçları</b></td><td><a href="/sonuc">/sonuc</a></td><td>Her test adımının sonucu buraya kaydedilir</td></tr>
<tr><td>API gateway</td><td><a href="http://localhost:8888/health">http://localhost:8888/health</a></td><td></td></tr>
</table>"""

ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
