#!/usr/bin/env python3
"""Test hesaplarını gerçek API üzerinden oluşturur (test-hesaplari.sh çağırır).

Yönetici sakinleri ve görevlileri ekler, her kişi kendi etkinleştirme koduyla şifresini
belirler; ikinci site (izolasyon testleri için) yönetici tarafından açılır. Böylece kayıt
akışının kendisi de her açılışta sınanmış olur.
"""
import json, re, sys, time, urllib.error, urllib.request

API = sys.argv[1].rstrip("/")
TOOLS = (sys.argv[2] if len(sys.argv) > 2 else "http://127.0.0.1:18000").rstrip("/")
PW = "Demo123!"
A = "11111111-1111-1111-1111-111111111111"
UNIT = {"A-3": "33333333-3333-3333-3333-333333333303", "A-4": "33333333-3333-3333-3333-333333333304",
        "B-1": "33333333-3333-3333-3333-333333333321", "B-2": "33333333-3333-3333-3333-333333333322"}


def call(method, path, body=None, token=None, ok=(200, 201, 202)):
    req = urllib.request.Request(API + path, method=method, data=json.dumps(body).encode() if body is not None else None,
                                 headers={"Content-Type": "application/json", **({"Authorization": "Bearer " + token} if token else {})})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            code, raw = r.status, r.read()
    except urllib.error.HTTPError as e:
        code, raw = e.code, e.read()
    data = json.loads(raw or b"{}")
    if code not in ok:
        sys.exit("HATA %s %s → %s %s" % (method, path, code, data))
    return data


def login(phone, full=False):
    r = call("POST", "/auth/login", {"phone": phone, "password": PW})
    return r if full else r["access_token"]


def switch(session, pid):
    call("POST", "/users/me/active-property", {"property_id": pid}, session["access_token"])
    return call("POST", "/auth/refresh", {"refresh_token": session["refresh_token"]})


def activate(phone, act):
    code = (act or {}).get("activation_code")
    if not code:
        sys.exit("HATA %s için etkinleştirme kodu dönmedi" % phone)
    call("POST", "/auth/activate", {"phone": phone, "code": code, "new_password": PW})


def resident(tok, first, last, phone, unit, role):
    r = call("POST", "/residents", {"first_name": first, "last_name": last, "phone": phone, "email": phone + "@siteeksen.test",
                                     "unit_id": unit, "role": role}, tok)
    activate(phone, r.get("activation"))


def staff(tok, first, last, phone, role):
    r = call("POST", "/property-roles", {"phone": phone, "role": role, "first_name": first, "last_name": last,
                                          "decision_ref": "Test kurulumu — kurul kararı 2026/1"}, tok)
    if r.get("activation"):
        activate(phone, r["activation"])


def sms_code(phone, pattern):
    """Sahte Netgsm kutusundan (test araçları) numaraya giden son kodu okur."""
    for _ in range(20):
        with urllib.request.urlopen(TOOLS + "/sms.json", timeout=10) as r:
            rows = json.loads(r.read() or b"[]")
        msgs = [m["msg"] for row in rows for m in row.get("body", {}).get("messages", []) if m.get("no", "").endswith(phone[-10:])]
        found = [re.search(pattern, m) for m in msgs]
        found = [f.group(1) for f in found if f]
        if found:
            return found[-1]
        time.sleep(0.5)
    sys.exit("HATA %s için SMS kodu gelmedi" % phone)


def supplier(first, last, phone):
    """Tedarikçi kaydı (076, FAZ M1): kod → doğrulama → hesap; gerçek akış."""
    call("POST", "/auth/supplier-signup/request", {"phone": phone})
    code = sms_code(phone, r"kayıt kodunuz: ([A-Z0-9]{8})")
    v = call("POST", "/auth/supplier-signup/verify", {"phone": phone, "code": code})
    call("POST", "/auth/supplier-signup/complete", {"phone": phone, "signup_token": v["signup_token"], "password": PW,
                                                     "first_name": first, "last_name": last, "terms_accepted": True})


sess = login("5551234567", full=True)
mgr = sess["access_token"]
resident(mgr, "Ayşe", "Kaya", "5550000010", UNIT["A-4"], "OWNER")
resident(mgr, "Fatma", "Şahin", "5550000011", UNIT["B-1"], "OWNER")
resident(mgr, "Ali", "Çelik", "5550000012", UNIT["B-1"], "PROXY")
resident(mgr, "Zeynep", "Arslan", "5550000001", UNIT["B-2"], "OWNER")
staff(mgr, "Zeynep", "Arslan", "5550000001", "BOARD_MEMBER")
staff(mgr, "Hasan", "Koç", "5550000002", "AUDITOR")
staff(mgr, "Murat", "Öz", "5550000003", "STAFF")

# İkinci site: yönetici açar (kurucu yönetici olur), bölüm ve bir malik ekler, sonra Güneş Sitesi'ne döner.
b = call("POST", "/users/me/properties", {"name": "Deniz Apartmanı (Test B)", "type": "APARTMENT", "address": "Sahil Yolu No:5",
                                           "city": "İzmir", "district": "Karşıyaka"}, mgr)
bid = (b.get("property") or b).get("id") or b.get("property_id")
if not bid:
    sys.exit("HATA ikinci site kimliği dönmedi: %s" % b)
sess_b = switch(sess, bid)
mgr_b = sess_b["access_token"]
units = call("POST", "/units", {"units": [{"block": "A", "floor": 1, "door_number": "1", "share_ratio": 500, "gross_area_m2": 90, "net_area_m2": 80, "owner_occupied": True},
                                           {"block": "A", "floor": 1, "door_number": "2", "share_ratio": 500, "gross_area_m2": 90, "net_area_m2": 80, "owner_occupied": True}]}, mgr_b)["data"]
resident(mgr_b, "Elif", "Yurt", "5550000020", units[0]["id"], "OWNER")
switch(sess_b, A)

supplier("Kemal", "Usta", "5550000040")
supplier("Selin", "Temiz", "5550000041")

for phone in ("5550000010", "5550000011", "5550000012", "5550000001", "5550000002", "5550000003", "5550000020", "5559876543",
              "5550000040", "5550000041"):
    login(phone)

print("""Hesaplar (hepsinin şifresi %s; giriş kontrol edildi):
  YÖNETİCİ   5551234567  Ahmet Yılmaz   Güneş Sitesi: MANAGER + BOARD_MEMBER, A-3 maliki; Deniz Apt. (Test B): kurucu yönetici
  KİRACI     5559876543  Mehmet Demir   A-4 kiracısı
  MALİK_A4   5550000010  Ayşe Kaya      A-4 maliki (dairesi kiracılı)
  MALİK_B1   5550000011  Fatma Şahin    B-1 maliki (kendisi oturuyor)
  VEKİL_B1   5550000012  Ali Çelik      B-1 vekili (PROXY)
  KURUL      5550000001  Zeynep Arslan  BOARD_MEMBER + B-2 maliki
  DENETÇİ    5550000002  Hasan Koç      AUDITOR
  GÖREVLİ    5550000003  Murat Öz       STAFF (güvenlik/görevli)
  SİTE_B     5550000020  Elif Yurt      Deniz Apt. (Test B) A-1 maliki — Güneş Sitesi'ni GÖRMEMELİ
  TEDARİKÇİ1 5550000040  Kemal Usta     Usta & Hizmet tedarikçisi (kendi kaydı) — /tedarikci
  TEDARİKÇİ2 5550000041  Selin Temiz    Usta & Hizmet tedarikçisi (kendi kaydı) — /tedarikci
  Site kimlikleri: Güneş Sitesi %s · Deniz Apt. %s""" % (PW, A, bid))
