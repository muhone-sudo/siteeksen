#!/usr/bin/env python3
"""Usta & Hizmet test verisi (FAZ M3.5, M4.6, M5.7) — gerçek API üzerinden.

Platform yöneticisi kategorileri ve ücretli paketi açar; iki test tedarikçisi hesap bilgisi, belge,
işletme ve hizmet kalemi girip incelemeye gönderir; platform onaylar; tedarikçiler sahte iyzico ile
bakiye yükler, biri ücretli pakete geçer. Sonunda her hesap için bakiye = defter toplamı denetlenir.
Kullanım: pazaryeri.py <API> <TOOLS>
"""
import json, sys, urllib.error, urllib.parse, urllib.request, uuid

API = sys.argv[1].rstrip("/")
TOOLS = (sys.argv[2] if len(sys.argv) > 2 else "http://127.0.0.1:18000").rstrip("/")
PW = "Demo123!"
PDF = b"%PDF-1.4\n1 0 obj<</Type/Catalog>>endobj\ntrailer<</Root 1 0 R>>\n%%EOF\n"
PNG = bytes.fromhex("89504e470d0a1a0a0000000d4948445200000001000000010806000000"
                    "1f15c4890000000d49444154789c6360000002000154a24f5d0000000049454e44ae426082")


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *a, **k):
        return None


def send(req, ok):
    try:
        with urllib.request.build_opener(NoRedirect).open(req, timeout=30) as r:
            code, raw = r.status, r.read()
    except urllib.error.HTTPError as e:
        code, raw = e.code, e.read()
    if code not in ok:
        sys.exit("HATA %s %s → %s %s" % (req.get_method(), req.full_url, code, raw[:300].decode(errors="replace")))
    try:
        return json.loads(raw or b"{}")
    except ValueError:
        return {}


def call(method, path, body=None, token=None, headers=None, ok=(200, 201)):
    h = {"Content-Type": "application/json", **({"Authorization": "Bearer " + token} if token else {}), **(headers or {})}
    return send(urllib.request.Request(API + path, method=method, headers=h,
                                       data=json.dumps(body).encode() if body is not None else None), ok)


def upload(path, token, fields, name, content, ctype):
    b = uuid.uuid4().hex
    parts = [("--%s\r\nContent-Disposition: form-data; name=\"%s\"\r\n\r\n%s\r\n" % (b, k, v)).encode() for k, v in fields.items()]
    parts.append(("--%s\r\nContent-Disposition: form-data; name=\"file\"; filename=\"%s\"\r\nContent-Type: %s\r\n\r\n" % (b, name, ctype)).encode()
                 + content + ("\r\n--%s--\r\n" % b).encode())
    return send(urllib.request.Request(API + path, method="POST", data=b"".join(parts),
                                       headers={"Authorization": "Bearer " + token, "Content-Type": "multipart/form-data; boundary=" + b}), (200, 201))


def form(url, fields, ok):
    return send(urllib.request.Request(url, method="POST", data=urllib.parse.urlencode(fields).encode(),
                                       headers={"Content-Type": "application/x-www-form-urlencoded"}), ok)


def login(phone):
    return call("POST", "/auth/login", {"phone": phone, "password": PW})["access_token"]


def topup(tok, kurus):
    """Sahte iyzico ödeme sayfasında "Ödeme başarılı" seçilir; tarayıcının yaptığı gibi dönüş ucuna jeton gönderilir."""
    terms = call("GET", "/market/terms/balance", token=tok)
    if not terms.get("accepted"):
        call("POST", "/market/supplier/terms/balance/accept", {"version": terms["version"]}, tok)
    r = call("POST", "/market/supplier/topups", {"amount_kurus": kurus}, tok, {"Idempotency-Key": str(uuid.uuid4())})
    pay_token = r["checkout_url"].rstrip("/").rsplit("/", 1)[-1]
    form(TOOLS + "/iyzico/pay/" + pay_token, {"sonuc": "SUCCESS"}, (200,))
    form(API + "/public/market/topups/iyzico/callback", {"token": pay_token}, (200, 302, 303))
    st = call("GET", "/market/supplier/topups/" + r["topup"]["id"], token=tok)
    if st.get("status") != "SUCCEEDED":
        sys.exit("HATA bakiye yüklemesi tamamlanmadı: %s" % st)


pa = login("5550000030")
cat = {}
for name, fee, scope in (("Tesisat", 7500, "BOTH"), ("Elektrik", 7500, "BOTH"), ("Daire temizliği", 5000, "RESIDENT"),
                         ("Boya badana", 10000, "BOTH"), ("Site temizliği", 15000, "MANAGEMENT"), ("Asansör bakımı", 20000, "MANAGEMENT")):
    cat[name] = call("POST", "/market/platform/categories", {"name": name, "request_fee_kurus": fee, "buyer_scope": scope}, pa)["id"]
pro = call("POST", "/market/platform/packages", {"name": "Usta Pro", "monthly_fee_kurus": 35000, "fee_discount_pct": 25, "included_requests": 5,
                                                 "monthly_sms": 50, "priority_access": True, "phone_in_showcase": True, "rank_weight": 10,
                                                 "is_active": True}, pa)["id"]

SUPPLIERS = [
    ("5550000040", {"trade_name": "Kemal Tesisat Ltd. Şti.", "tax_number": "1234567890", "tax_office": "Kadıköy"}, [
        ({"name": "Kemal Tesisat Kadıköy", "description": "Su tesisatı, kombi ve elektrik arızaları", "phone": "0216 555 00 40",
          "address": "Moda Cad. No:12", "city": "İstanbul", "district": "Kadıköy", "latitude": 40.9871, "longitude": 29.0262,
          "service_area": "KM", "radius_km": 15, "category_ids": [cat["Tesisat"], cat["Elektrik"]]},
         [{"name": "Musluk değişimi", "description": "Malzeme hariç", "price_min_kurus": 30000, "price_max_kurus": 60000, "unit": "adet"},
          {"name": "Kombi bakımı", "price_min_kurus": 120000, "price_max_kurus": 180000, "unit": "adet"},
          {"name": "Petek temizliği", "description": "Fiyat petek sayısına göre"}]),
        ({"name": "Kemal Tesisat Ataşehir", "description": "Tesisat ve site ortak alan işleri", "phone": "0216 555 00 41",
          "address": "Atatürk Mah. Ataşehir Bulvarı No:5", "city": "İstanbul", "district": "Ataşehir", "latitude": 40.9923, "longitude": 29.1244,
          "service_area": "CITY", "radius_km": None, "category_ids": [cat["Tesisat"], cat["Site temizliği"]]},
         [{"name": "Kaçak tespiti", "price_min_kurus": 150000, "price_max_kurus": 300000, "unit": "iş"}]),
    ]),
    ("5550000041", {"trade_name": "Selin Temizlik", "tax_number": "9876543210", "tax_office": "Üsküdar"}, [
        ({"name": "Selin Temizlik", "description": "Ev, ofis ve site temizliği", "phone": "0216 555 00 50",
          "address": "Bağlarbaşı Mah. No:8", "city": "İstanbul", "district": "Üsküdar", "latitude": 41.0201, "longitude": 29.0365,
          "service_area": "KM", "radius_km": 20, "category_ids": [cat["Daire temizliği"], cat["Site temizliği"], cat["Boya badana"]]},
         [{"name": "Daire temizliği (3+1)", "price_min_kurus": 250000, "price_max_kurus": 350000, "unit": "daire"},
          {"name": "Merdiven ve ortak alan temizliği", "unit": "ay"}]),
    ]),
]

for phone, acc, businesses in SUPPLIERS:
    tok = login(phone)
    account = call("POST", "/market/supplier/account", {**acc, "terms_accepted": True}, tok)
    upload("/market/supplier/documents", tok, {"doc_type": "TAX_PLATE"}, "vergi-levhasi.pdf", PDF, "application/pdf")
    upload("/market/supplier/documents", tok, {"doc_type": "ID_CARD"}, "kimlik.png", PNG, "image/png")
    call("POST", "/market/supplier/account/submit", token=tok)
    call("POST", "/market/platform/accounts/%s/approve" % account["id"], token=pa)
    for biz, services in businesses:
        bid = call("POST", "/market/supplier/businesses", biz, tok)["id"]
        for s in services:
            call("POST", "/market/supplier/businesses/%s/services" % bid, s, tok)
        call("POST", "/market/supplier/businesses/%s/submit" % bid, token=tok)
        call("POST", "/market/platform/businesses/%s/approve" % bid, token=pa)

kemal, selin = login("5550000040"), login("5550000041")
topup(kemal, 100000)
call("POST", "/market/supplier/package", {"package_id": pro}, kemal)
topup(selin, 20000)

for phone, tok in (("5550000040", kemal), ("5550000041", selin)):
    w = call("GET", "/market/supplier/wallet?limit=200", token=tok)
    total = sum(x["amount_kurus"] for x in w["data"])
    if w["total"] > len(w["data"]) or total != w["balance_kurus"]:
        sys.exit("HATA %s bakiye %s ≠ defter toplamı %s" % (phone, w["balance_kurus"], total))

print("""Usta & Hizmet test verisi (bakiye = defter toplamı denetlendi):
  Kategoriler: Tesisat, Elektrik, Boya badana (sakin + yönetim) · Daire temizliği (sakin) · Site temizliği, Asansör bakımı (yönetim)
  Paketler: Ücretsiz · Usta Pro (350 TL/ay, %25 indirim, 5 dahil talep, 50 SMS, öncelik, vitrinde telefon)
  TEDARİKÇİ1 Kemal Tesisat — onaylı; 2 işletme yayında (Kadıköy 15 km, Ataşehir tüm il); Usta Pro; bakiye 650 TL
  TEDARİKÇİ2 Selin Temizlik — onaylı; 1 işletme yayında (Üsküdar 20 km); Ücretsiz paket; bakiye 200 TL""")
