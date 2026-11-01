#!/usr/bin/env python3
"""Özellik haritasından tarayıcı test planını üretir.

Girdi: gen.py'nin yazdığı <iş-dizini>/harita.json ve triggers.json.
Çıktı: docs/test-plani/ altındaki üretilen bölümler ve hepsinin birleşimi TEST-PLANI-TAMAMI.md.
Elle yazılan bölümler (00, 01, 08) aynı klasördedir; bu betik onlara dokunmaz, yalnız birleşik dosyaya katar.
"""
import json, os, re, sys

REPO, S, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
H = json.load(open(os.path.join(S, "harita.json")))
TRIG = json.load(open(os.path.join(S, "triggers.json")))
ROUTES = {r["key"]: r for r in H["routes"]}
CONS = H["consumers"]
GEN = "> Bu dosya koddan üretilir (`bash docs/ozellik-haritasi/arac/uret.sh`); elle düzenlemeyin. Kurallar, hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md)."

PANEL, SAKIN, YON = "http://localhost:3001", "http://localhost:3002/#", "http://localhost:3003/#"
ACC = {
    "YÖNETİCİ": ("5551234567", {"MANAGER", "BOARD_MEMBER", "OWNER"}),
    "KURUL": ("5550000001", {"BOARD_MEMBER", "OWNER"}),
    "DENETÇİ": ("5550000002", {"AUDITOR"}),
    "GÖREVLİ": ("5550000003", {"STAFF"}),
    "KİRACI": ("5559876543", {"TENANT"}),
    "MALİK_A4": ("5550000010", {"OWNER"}),
    "MALİK_B1": ("5550000011", {"OWNER"}),
    "VEKİL_B1": ("5550000012", {"PROXY"}),
    "SİTE_B": ("5550000020", {"OWNER"}),
}
PANEL_ACC = ["YÖNETİCİ", "KURUL", "DENETÇİ", "GÖREVLİ", "KİRACI"]
AUDIENCE = {
    "Residents": ("sitenin bütün aktif sakinleri", ["YÖNETİCİ", "KİRACI", "MALİK_A4", "MALİK_B1", "VEKİL_B1", "KURUL"]),
    "UnitResidents": ("ilgili dairenin aktif sakinleri", None),
    "UnitUsers": ("ilgili dairenin kullanıcıları (kiracılı dairede yalnız kiracı; kiracısızda malik ve vekil)", None),
    "AssessmentPayers": ("borcun sorumlusu (kullanım borcunda kiracı; malik borcunda malik ve vekil)", None),
    "NotifyCharges": ("borcun sorumlusu", None),
    "BlockNeighbors": ("aynı bloktaki diğer dairelerin sakinleri", None),
    "Tenants": ("sitenin kiracıları", ["KİRACI"]),
    "UnitOwners": ("ilgili dairenin malik ve vekilleri", None),
    "Managers": ("yönetim (MANAGER, BOARD_MEMBER, AUDITOR)", ["YÖNETİCİ", "KURUL", "DENETÇİ"]),
    "Approvers": ("onay yetkilileri (MANAGER, BOARD_MEMBER)", ["YÖNETİCİ", "KURUL"]),
    "Operations": ("saha (MANAGER, BOARD_MEMBER, STAFF)", ["YÖNETİCİ", "KURUL", "GÖREVLİ"]),
}
UNIT_EXAMPLES = "Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL."
COMMON = {"units", "users", "resident_units", "properties", "property_roles", "legal_parameters", "unit_occupancy", "audit_logs",
          "blocks", "property_settings"}
SAKIN_ACC = {
    "tenancy_requests_screen": "KİRACI (kiracılık bitişi talebini yanıtlar) ve MALİK_A4 (talebi açar)",
    "owner_visibility_screen": "MALİK_A4", "unit_residents_screen": "MALİK_A4",
    "vehicles_screen": "KİRACI", "my_visitors_screen": "KİRACI", "visitor_preregister_screen": "KİRACI",
    "create_reservation_screen": "KİRACI", "my_reservations_screen": "KİRACI", "package_tracking_mobile_screen": "KİRACI",
    "my_meters_screen": "KİRACI", "dues_payment_screen": "KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi)",
    "payment_history_screen": "KİRACI", "my_budgets_screen": "MALİK_B1 (işletme projesi malik içindir)",
    "login_screen": "her hesap", "activate_account_screen": "yeni sakin (01-oturum-ve-hesap.md)",
}
YON_ACC = {"patrol_run_screen": "GÖREVLİ", "patrol_report_screen": "YÖNETİCİ", "checkpoint_setup_screen": "YÖNETİCİ"}


def slug(s):
    t = s.lower().translate(str.maketrans("çğıöşüâ", "cgiosua"))
    return re.sub(r"[^a-z0-9]+", "-", t).strip("-").upper()[:28]


def can_panel(url, roles):
    best = None
    for p, rs, why in H["rules"]:
        if url == p or url.startswith(p + "/"):
            if not best or len(p) > len(best[0]):
                best = (p, rs)
    if best is None:
        return True
    return bool(set(best[1]) & roles)


def q_table(t):
    return "SELECT xmin, * FROM %s ORDER BY xmin::text::bigint DESC LIMIT 5;" % t


def topic_prefix(t):
    return re.split(r"[{(…]", t)[0].rstrip(".")


def q_notif(topics):
    conds = " OR ".join("n.topic LIKE '%s%%'" % topic_prefix(t) for t in topics)
    return ("SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject "
            "FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE %s ORDER BY n.created_at DESC LIMIT 30;" % conds)


def place(who):
    if who.startswith("Panel "):
        u = who[6:]
        return "Panel `%s`" % (u if u.startswith("/") else "/" + u)
    if who.startswith("Sakin "):
        return "Sakin `%s`" % who[6:]
    if who.startswith("Yönetici-mobil "):
        return "Yön.mobil `%s`" % who[15:]
    return who


def effects(call):
    out = []
    for w in call.get("writes", []):
        op, t = w.split(" ", 1)
        if t in COMMON:
            continue
        readers = [k for k, r in ROUTES.items() if r["method"] == "GET" and t in (r.get("reads") or [])]
        places = sorted(set(place(c) for k in readers for c in CONS.get(k, [])))
        out.append((op, t, readers, places))
    return out


def audience_text(call):
    aud = [a for a in call.get("audience", []) if a]
    if not aud:
        return "işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta", []
    parts, accs, unit = [], [], False
    for a in aud:
        name = a.split(" ")[0]
        desc, who = AUDIENCE.get(name, (a, None))
        parts.append("%s (`%s`)" % (desc, name))
        if who is None:
            unit = True
        else:
            accs += who
    txt = "; ".join(parts) + ("  \n      " + UNIT_EXAMPLES if unit else "")
    return txt, sorted(set(accs), key=list(ACC).index)


def inbox_of(acc):
    if acc in ("YÖNETİCİ", "KURUL", "DENETÇİ"):
        return "panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler"
    if acc == "GÖREVLİ":
        return "panel zil simgesi, Yön.mobil Bildirimler"
    return "Sakin uygulaması Bildirimler (zil)"


def method_action(m):
    return {"POST": "CREATE", "PUT": "UPDATE", "PATCH": "UPDATE", "DELETE": "DELETE"}.get(m, "VIEW")


SEEN_IDS = set()


def uniq(cid):
    base, n = cid, 2
    while cid in SEEN_IDS:
        cid = "%s-%d" % (base, n)
        n += 1
    SEEN_IDS.add(cid)
    return cid


def case(o, cid, title, account, where, steps, calls, deny=None, extra=None, page=False, opens=False):
    cid = uniq(cid)
    o.append("#### %s · %s" % (cid, title))
    o.append("- **Hesap:** %s · **Nerede:** %s" % (account, where))
    for s in steps:
        o.append("- **Adım:** %s" % s)
    writes = [c for c in calls if not c.get("missing") and c["method"] != "GET"]
    reads = [c for c in calls if not c.get("missing") and c["method"] == "GET"]
    missing = [c for c in calls if c.get("missing")]
    if page:
        o.append("- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; \"undefined\", \"NaN\", \"null\", ham JSON ya da İngilizce hata metni YOK); "
                 "sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.")
    elif not calls and opens:
        o.append("- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. "
                 "Formun gönderimi aynı ekrandaki \"Form: …\" testindedir.")
    elif not calls:
        o.append("- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.")
    for c in calls:
        if c.get("dead"):
            o.append("- **Beklenen:** `%s` bilerek yazılmadı (S-07): ekran **501 / \"henüz hazır değil\"** benzeri dürüst bir mesaj göstermeli; uydurma veri GÖSTERMEMELİ." % c["key"])
    if reads:
        o.append("- **Beklenen (okuma):** %s — veri yüklenir; boşsa \"kayıt yok\" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil)." %
                 ", ".join("`%s` (%s)" % (c["key"], c["svc"]) for c in reads))
        if any(c.get("storage") for c in reads):
            o.append("- **Beklenen (dosya):** dosya iner/açılır; boş ya da bozuk değildir (PDF ise sayfalar okunur).")
    for c in writes:
        if c.get("dead"):
            continue
        o.append("- **Beklenen (yazma):** `%s` (%s, `%s`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür." % (c["key"], c["svc"], c["where"]))
        o.append("  - Sunucu yetkisi: %s" % c["roles"])
        if c.get("triggers"):
            o.append("  - Veritabanı tetikleyicileri çalışır: %s (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)" % ", ".join("`%s`" % t for t in c["triggers"]))
        if c.get("storage"):
            o.append("  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı")
        eff = effects(c)
        if c.get("writes"):
            o.append("  - **Veritabanı (Adminer → SQL komutu):**")
            for op, t, rd, places in eff:
                verb = {"INSERT": "yeni satır eklenmiş", "UPDATE": "ilgili satır güncellenmiş", "DELETE": "satır silinmiş"}[op]
                o.append("    - `%s` — %s olmalı: `%s`" % (t, verb, q_table(t)))
            commons = sorted(set(w.split(" ", 1)[1] for w in c["writes"] if w.split(" ", 1)[1] in COMMON and w.split(" ", 1)[1] != "audit_logs"))
            if commons:
                o.append("    - Ortak tablolar da değişir: %s (aynı sorgu kalıbıyla bakılabilir)" % ", ".join("`%s`" % t for t in commons))
        o.append("  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1%s' ORDER BY created_at DESC LIMIT 5;` → `%s`, 2xx (yetkisiz denemede `DENIED`, 403)" % (c["path"], method_action(c["method"])))
        if c.get("topics") or c.get("audience"):
            txt, accs = audience_text(c)
            o.append("  - **Bildirim:** konu %s → alıcı: %s" % (", ".join("`%s`" % t for t in c["topics"] or ["?"]), txt))
            o.append("    - Sorgu: `%s`" % q_notif(c["topics"] or ["%"]))
            if accs:
                o.append("    - Şu hesaplarla bildirim kutusunda görünmeli: %s" % "; ".join("%s → %s" % (a, inbox_of(a)) for a in accs))
            o.append("    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**")
        else:
            o.append("  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.")
        vis = sorted(set(p for _, _, _, ps in eff for p in ps))
        if vis:
            o.append("  - **Etkisi görülmeli:** %s" % ", ".join(vis[:18]) + (" (+%d yer daha)" % (len(vis) - 18) if len(vis) > 18 else ""))
    for c in missing:
        o.append("- **Beklenen:** `%s` backend'de karşılığı bulunmadı — çağrılırsa 404 olur; KALDI say ve gözleme yaz." % c["key"])
    if deny:
        o.append("- **Yetki (olumsuz):** %s" % deny)
    for e in extra or []:
        o.append("- %s" % e)
    o.append("- **Sonuç:** http://localhost:18000/sonuc → `%s`" % cid)
    o.append("")


def deny_text(calls, desc, allowed_accounts):
    msgs = []
    for c in calls:
        if c.get("missing") or c["method"] == "GET" or not c.get("role_list"):
            continue
        need = set(c["role_list"])
        bad = [a for a in allowed_accounts if not (ACC[a][1] & need)]
        if bad:
            msgs.append("%s ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda \"yetkiniz yok\" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`%s` yalnız %s)." % (
                ", ".join(bad), c["key"], "/".join(c["role_list"])))
    if not msgs and "yalnız yazma yetkisi" in desc:
        bad = [a for a in allowed_accounts if not (ACC[a][1] & {"MANAGER", "BOARD_MEMBER"})]
        if bad:
            msgs.append("%s ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER)." % ", ".join(bad))
    for c in calls:
        if not c.get("missing") and "resident_can_use" in (c.get("roles") or ""):
            msgs.append("Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.")
            break
    return " ".join(dict.fromkeys(msgs)) or None


def page_checks(view):
    out = []
    for v in view:
        v = v.lstrip("- ")
        if v.startswith("Veri"):
            out.append("Veri yüklenir: " + v.split(":", 1)[1].strip())
        elif v.startswith("Tablo"):
            out.append("Tablo sütunları görünür ve dolu/boş durumu doğru: " + v.split(":", 1)[1].strip())
        elif v.startswith("Sekmeler"):
            out.append("Her sekmeye tıkla, içerik hatasız yüklenir: " + v.split(":", 1)[1].strip())
        elif v.startswith(("Kart", "Başlık", "Bilgi notu", "Pencere", "Mesaj", "Bağlantı", "Alan", "Dosya", "Bileşen")):
            out.append(v)
    return out


def section_header(title, intro):
    return ["# " + title, "", GEN, "", intro, ""]


# ---------------- PANEL ----------------
def write_panel():
    groups = {}
    for p in H["pages"]["panel"]:
        groups.setdefault(p["section"], []).append(p)
    files = []
    names = {"Üst": "ust", "Sakinler ve İletişim": "sakinler-iletisim", "Mali": "mali", "Yönetişim (KMK)": "yonetisim",
             "Operasyon": "operasyon", "Analiz": "analiz", "Sistem": "sistem", "Kenar çubuğu altı": "ayarlar", "Menü dışı": "menu-disi"}
    total = 0
    for i, (sec, pages) in enumerate(groups.items(), 1):
        fn = "03-%02d-panel-%s.md" % (i, names.get(sec, slug(sec).lower()))
        o = section_header("3.%d Panel — %s" % (i, sec),
                           "Panel: %s. Her sayfa için önce **sayfa açılışı** (…-00), sonra sayfadaki her düğme/form/seçim sırayla denenir. "
                           "Formlarda önce zorunlu alanları boş bırakıp gönder (doğrulama hatası beklenir, kayıt OLUŞMAMALI), sonra gerçekçi değerlerle doldur. "
                           "Girilen değerleri gözleme yaz; sonraki adımlar ve senaryolar bu kayıtları kullanır." % PANEL)
        for p in pages:
            pid = "P-" + slug(p["url"].replace("/dashboard", "") or "ANA")
            dyn = "[" in p["url"]
            allowed = [a for a in PANEL_ACC if p["access"] is None or set(p["access"]) & ACC[a][1]]
            o.append("### %s — `%s`" % (p["title"], p["url"]))
            o.append("- Dosya: `%s`" % p["file"])
            o.append("- Panel erişimi: %s" % ("/".join(p["access"]) + " — " + p["access_reason"] if p["access"] else "herkese açık"))
            o.append("")
            url = PANEL + p["url"] if not dyn else "%s%s (listeden bir kayda tıklanarak açılır)" % (PANEL, re.sub(r"/\[[^\]]+\]", "/…", p["url"]))
            checks = page_checks(p["view"])
            steps = ["%s adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı" % url]
            steps += checks
            steps.append("Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez")
            if p["access"]:
                denied = [a for a in PANEL_ACC if not (set(p["access"]) & ACC[a][1])]
                if denied:
                    steps.append("Erişimi olmayan hesapla (%s) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli" % ", ".join(denied))
            case(o, pid + "-00", "Sayfa açılışı ve ekran kontrolleri", "YÖNETİCİ (sonra %s ile yalnız görüntüleme)" % ", ".join(a for a in allowed if a != "YÖNETİCİ") if len(allowed) > 1 else "YÖNETİCİ",
                 url, steps, [], page=True)
            for a in p["actions"]:
                kind = {"DÜĞME": "Düğme", "FORM": "Form", "SEÇİM": "Seçim", "DEĞİŞİMDE": "Seçim"}[a["kind"]]
                desc = a["desc"]
                label = desc.split(" — ")[0].split(" (")[0] or "(başlık dinamik)"
                steps = []
                if a["kind"] == "FORM":
                    m = re.search(r"alanlar: ([^—]+)", desc)
                    if m:
                        steps.append("Formu aç; alanlar: %s (* zorunlu)" % m.group(1).strip())
                        if "*" in m.group(1):
                            steps.append("Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI")
                        steps.append("Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz")
                    else:
                        steps.append("Formu gerçekçi değerlerle doldur ve gönder")
                    b = re.search(r"başarı: (.+)$", desc)
                    if b and b.group(1).strip():
                        steps.append("Başarı mesajı tam olarak şu anlamda olmalı: \"%s\"" % b.group(1).strip())
                elif a["kind"] in ("SEÇİM", "DEĞİŞİMDE"):
                    steps.append("Seçimi değiştir (her seçeneği en az bir kez dene); liste/içerik seçime göre değişmeli")
                else:
                    steps.append("\"%s\" %s öğesine bas%s" % (label, "düğme" if kind == "Düğme" else kind.lower(),
                                                           " (onay penceresi çıkarsa önce Vazgeç → hiçbir şey değişmemeli; sonra tekrar bas ve onayla)" if a["calls"] and any(c.get("method") in ("DELETE",) or "iptal" in desc.lower() or "sil" in desc.lower() for c in a["calls"] if not c.get("missing")) else ""))
                    if a["calls"] and "pencere/form açar" in desc:
                        steps.append("Açılan pencerede alanları gerçekçi değerlerle doldurup onayla")
                if a["comp"]:
                    steps.append("Öğe `%s` bileşenindedir (satır %d)" % (a["comp"], a["line"]))
                acc = "YÖNETİCİ"
                for c in a["calls"]:
                    if not c.get("missing") and c.get("role_list") and c["method"] != "GET":
                        for cand in ("YÖNETİCİ", "KURUL", "GÖREVLİ", "DENETÇİ"):
                            if ACC[cand][1] & set(c["role_list"]) and cand in allowed:
                                acc = cand
                                break
                        break
                case(o, "%s-%02d" % (pid, a["n"]), "%s: %s" % (kind, label), acc, url, steps, a["calls"],
                     deny_text(a["calls"], desc, [x for x in allowed if x != acc]), opens="açar" in desc)
                total += 1
            o.append("---")
            o.append("")
        open(os.path.join(OUT, fn), "w").write("\n".join(o))
        files.append((fn, "Panel — %s" % sec, len(pages)))
    return files, total


# ---------------- MOBİL ----------------
def full_routes(app):
    src = open(os.path.join(REPO, app, "lib/core/router/app_router.dart"), encoding="utf-8").read()

    def close(i):
        d, q, j = 0, None, i
        while j < len(src):
            ch = src[j]
            if q:
                if ch == q and src[j - 1] != "\\":
                    q = None
            elif ch in "'\"":
                q = ch
            elif ch in "([{":
                d += 1
            elif ch in ")]}":
                d -= 1
                if d == 0:
                    return j
            j += 1
        return len(src)

    spans = []
    for m in re.finditer(r"GoRoute\(", src):
        st = m.end() - 1
        en = close(st)
        pm = re.search(r"path:\s*'([^']*)'", src[st:en])
        spans.append([st, en, pm.group(1) if pm else ""])
    res = {}
    for i, (st, en, path) in enumerate(spans):
        parents = [s for s in spans if s[0] < st and s[1] > en]
        full = path
        for ps in sorted(parents, key=lambda s: -s[0]):
            if not full.startswith("/"):
                full = ps[2].rstrip("/") + "/" + full
        children = [s for s in spans if s[0] > st and s[1] < en]
        body = src[st:en]
        for cs in sorted(children, key=lambda s: -s[0]):
            body = body[:cs[0] - st] + body[cs[1] - st:]
        bm = re.search(r"builder:\s*\([^)]*\)\s*(?:=>|\{[^}]*return)\s*(?:const\s+)?(\w+)\(", body, re.S)
        if bm:
            res.setdefault(bm.group(1), []).append(full)
    return res


def write_mobile(app, fn, title, base, prefix, default_acc, accmap):
    rmap = full_routes(app)
    o = section_header(title, "Uygulama: %s (web derlemesi; tarayıcı penceresini telefon genişliğine — ~400 px — daraltın ya da cihaz araç çubuğunu kullanın). "
                       "Adres çubuğuna `%s/<rota>` yazarak ekrana doğrudan gidilebilir; oturum yoksa giriş ekranına yönlenir. "
                       "Web derlemesinde kamera (QR) ve konum (GPS) tarayıcı izniyle çalışır; izin penceresinde \"İzin ver\" seçin. "
                       "Biyometrik giriş web'de yoktur (düğmesi görünmemeli)." % (base.rstrip("/#"), base))
    total = 0
    for p in H["pages"][app]:
        if not p["actions"] and not any(v.lstrip("- ").startswith("Veri") for v in p["view"]):
            continue
        sid = "%s-%s" % (prefix, slug(p["title"].replace("_screen", "").replace("_mobile", "")))
        cls = None
        src = open(os.path.join(REPO, p["file"]), encoding="utf-8").read()
        routes = []
        for c in re.findall(r"class (\w+) extends (?:StatefulWidget|StatelessWidget|ConsumerWidget|ConsumerStatefulWidget)", src):
            routes += rmap.get(c, [])
        routes = sorted(set(routes))
        acc = accmap.get(p["title"], default_acc)
        where = ", ".join("%s%s" % (base, r) for r in routes) if routes else "%s (başka bir ekrandan açılan bileşen/pencere; `%s`)" % (base.rstrip("#").rstrip("/"), p["file"])
        o.append("### %s" % p["title"])
        o.append("- Dosya: `%s`" % p["file"])
        o.append("")
        steps = ["Ekranı aç: %s — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı" % where] + page_checks(p["view"])
        steps.append("Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir")
        case(o, sid + "-00", "Ekran açılışı ve görünüm", acc, where, steps, [], page=True)
        for a in p["actions"]:
            kind = {"DÜĞME": "Düğme", "FORM": "Form", "SEÇİM": "Seçim", "DEĞİŞİMDE": "Seçim"}[a["kind"]]
            desc = a["desc"]
            label = desc.split(" — ")[0].split(" (")[0] or "(simge düğmesi)"
            if label in ("?", "None"):
                label = "simge düğmesi (satır %d)" % a["line"]
            steps = []
            if a["kind"] in ("SEÇİM", "DEĞİŞİMDE"):
                steps.append("\"%s\" seçimini değiştir; her seçenekte içerik buna göre değişmeli" % label)
            else:
                steps.append("\"%s\" öğesine dokun (kaynak satırı %d)%s" % (label, a["line"], "; açılan pencere/formu gerçekçi değerlerle doldurup onayla" if "pencere" in desc or "form" in desc else ""))
            if "dış bağlantı" in desc:
                steps.append("Dış bağlantı yeni sekmede açılır (kart ödemesinde sahte iyzico sayfası: http://localhost:18000/iyzico/pay/…)")
            case(o, "%s-%02d" % (sid, a["n"]), "%s: %s" % (kind, label), acc, where, steps, a["calls"], deny_text(a["calls"], desc, []), opens="açar" in desc)
            total += 1
        o.append("---")
        o.append("")
    open(os.path.join(OUT, fn), "w").write("\n".join(o))
    return total


# ---------------- ROL MATRİSİ ----------------
def write_roles():
    o = section_header("2. Rol, erişim ve site izolasyonu",
                       "Her hesapla panele girip aşağıdaki her adresi adres çubuğuna yazarak açın. **Erişir** = sayfa açılır ve kenar çubuğunda menüsü görünür; "
                       "**Yönlenir** = `/dashboard/forbidden` sayfası açılır (kendi rollerini ve gereken rolleri yazar), menüde görünmez. "
                       "KİRACI (yalnız sakin) panelin hiçbir sayfasına giremez. Panel denetimi kolaylıktır; asıl yetki sunucudadır (sayfa bölümlerindeki 'Yetki (olumsuz)' satırları).")
    o += ["| ID | Adres | Gereken rol | " + " | ".join(PANEL_ACC) + " |", "|---|---|---|" + "---|" * len(PANEL_ACC)]
    for p in H["pages"]["panel"]:
        if "[" in p["url"]:
            continue
        rid = "R-" + slug(p["url"].replace("/dashboard", "") or "ANA")
        cells = ["Erişir" if (p["access"] is None or set(p["access"]) & ACC[a][1]) else "Yönlenir" for a in PANEL_ACC]
        o.append("| %s | `%s` | %s | %s |" % (rid, p["url"], "/".join(p["access"] or ["—"]), " | ".join(cells)))
    o += ["", "Her satır bir test ID'sidir; satırdaki beş hesabın hepsi beklendiği gibiyse GEÇTİ, biri farklıysa KALDI (gözleme hangi hesap).", ""]
    o += ["## 2.2 Denetçi (AUDITOR) yazamaz", "",
          "#### R-DENETCI-YAZAMAZ · Denetçi bütün sayfalarda yalnız okur",
          "- **Hesap:** DENETÇİ · **Nerede:** erişebildiği her panel sayfası",
          "- **Adım:** Erişebildiği her sayfada ekle/düzenle/sil/onayla düğmelerini ara",
          "- **Beklenen:** yazma düğmeleri görünmez ya da pasiftir; görünen bir düğmeye basılırsa sunucu 403 döner, ekranda yetki mesajı çıkar, veritabanında değişiklik olmaz (Q-AUDIT'te `DENIED`)",
          "- **Sonuç:** `R-DENETCI-YAZAMAZ`", "",
          "## 2.3 Görevli (STAFF)", "",
          "#### R-GOREVLI-SINIR · Görevli yalnız operasyon ekranlarını kullanır",
          "- **Hesap:** GÖREVLİ · **Nerede:** panel ve yönetici uygulaması",
          "- **Adım:** Ziyaretçi, kargo, otopark, devriye, sayaç, talep ekranlarında işlem yap; personel, mali, ayarlar sayfalarına gitmeyi dene",
          "- **Beklenen:** operasyon işlemleri çalışır; personel/mali/ayarlar sayfaları yönlenir; Yön.mobil'de bu menüler görünmez",
          "- **Sonuç:** `R-GOREVLI-SINIR`", "",
          "## 2.4 Site izolasyonu (iki site)", "",
          "Güneş Sitesi ve Deniz Apartmanı (Test B) ayrı sitelerdir. Veri hiçbir yoldan karşı siteye geçmemeli.", "",
          "#### R-IZOLASYON-01 · Diğer sitenin sakini Güneş Sitesi verisini göremez",
          "- **Hesap:** SİTE_B · **Nerede:** Sakin uygulaması (http://localhost:3002)",
          "- **Adım:** Giriş yap; duyurular, ilanlar, anketler, belgeler, borçlar, bildirimler ekranlarını gez",
          "- **Beklenen:** yalnız Deniz Apartmanı verisi; Güneş Sitesi'nin duyuru/ilan/anket/belgesi hiçbir ekranda yok; site seçicide yalnız Deniz Apartmanı",
          "- **Sonuç:** `R-IZOLASYON-01`", "",
          "#### R-IZOLASYON-02 · Yönetici site değiştirince bütün ekranlar diğer siteye geçer",
          "- **Hesap:** YÖNETİCİ · **Nerede:** panel kenar çubuğundaki site seçici",
          "- **Adım:** Güneş Sitesi'nde bir duyuru yayımla; site seçiciden Deniz Apartmanı'na geç; Sakinler, Duyurular, Aidat, Giderler sayfalarına bak; geri Güneş Sitesi'ne geç",
          "- **Beklenen:** Deniz Apartmanı'nda Güneş Sitesi'nin duyurusu ve sakinleri yok (yalnız A-1/A-2 bölümleri ve Elif Yurt); geri dönünce Güneş Sitesi verisi eksiksiz",
          "- **Veritabanı:** `SELECT property_id, count(*) FROM announcements GROUP BY 1;` — duyuru doğru site kimliğiyle yazılmış olmalı",
          "- **Sonuç:** `R-IZOLASYON-02`", "",
          "#### R-IZOLASYON-03 · Adres çubuğuyla başka sitenin kaydına erişilemez",
          "- **Hesap:** SİTE_B ile panel de denenebilir (yönetici değildir → yönlenir); YÖNETİCİ Deniz Apartmanı'ndayken",
          "- **Adım:** Güneş Sitesi'ndeki bir sakin/duyuru/belge kaydının ayrıntı adresini (Güneş Sitesi aktifken kopyala) Deniz Apartmanı aktifken aç",
          "- **Beklenen:** kayıt bulunamadı / 404; Güneş Sitesi verisi görünmez",
          "- **Sonuç:** `R-IZOLASYON-03`", "",
          "#### R-IZOLASYON-04 · Bildirimler siteye bağlıdır",
          "- **Hesap:** SİTE_B",
          "- **Adım:** Güneş Sitesi'nde tüm sakinlere duyuru/bildirim gönderildikten sonra SİTE_B'nin bildirim kutusuna, SMS kutusuna (5550000020) ve Mailpit'e (5550000020@siteeksen.test) bak",
          "- **Beklenen:** Güneş Sitesi'nin hiçbir bildirimi SİTE_B'ye gitmemiş",
          "- **Veritabanı:** `SELECT count(*) FROM notifications n JOIN users u ON u.id = n.recipient_user_id WHERE u.phone = '+905550000020' AND n.property_id = '11111111-1111-1111-1111-111111111111';` → 0",
          "- **Sonuç:** `R-IZOLASYON-04`", ""]
    o += ["## 2.5 Yönetici uygulamasında rol", "",
          "#### R-YONMOBIL-ROL · Yönetici uygulaması rol süzmesi",
          "- **Hesap:** sırayla YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI · **Nerede:** http://localhost:3003",
          "- **Adım:** Her hesapla giriş yap, ana menüdeki grupları ve öğeleri listele",
          "- **Beklenen:** YÖNETİCİ her şeyi görür; DENETÇİ yazma düğmelerini görmez; GÖREVLİ yalnız operasyon öğelerini görür; KİRACI girişte yönetim yetkisi olmadığı uyarısını alır",
          "- **Sonuç:** `R-YONMOBIL-ROL`", ""]
    open(os.path.join(OUT, "02-rol-ve-izolasyon.md"), "w").write("\n".join(o))


# ---------------- BİLDİRİMLER ----------------
def write_notifications():
    o = section_header("6. Bildirimler — kim, ne zaman, hangi kanaldan",
                       "Bu bölüm bildirimleri **alıcı tarafından** doğrular: sayfa bölümlerinde işlemi yaptıktan sonra burada o konunun gerçekten doğru kişilere, "
                       "doğru kanaldan gittiğini ve yanlış kişilere gitmediğini kontrol edin. Kutular: panel zil simgesi + `/dashboard/inbox` (yönetim), "
                       "Sakin uygulaması Bildirimler, Yön.mobil Bildirimler; SMS kutusu http://localhost:18000/sms; e-posta Mailpit http://localhost:18025. "
                       "PUSH sağlayıcısı yoktur: `channel = 'PUSH'` satırları `PENDING` kalmalı (bu doğru davranıştır).")
    o += ["## 6.1 Genel bildirim kuralları", "",
          "#### B-GENEL-01 · Okundu bilgisi",
          "- **Hesap:** YÖNETİCİ (panel) ve KİRACI (sakin uygulaması)",
          "- **Adım:** Okunmamış bildirimi olan hesapla zil simgesindeki sayıyı not et; bir bildirime tıkla; \"Tümünü okundu say\"",
          "- **Beklenen:** sayı bir azalır, bildirim soluklaşır; tümü okununca sayı kaybolur; sayfa yenilenince durum korunur",
          "- **Veritabanı:** `SELECT r.read_at, n.topic FROM notification_reads r JOIN notifications n ON n.id = r.notification_id ORDER BY r.read_at DESC LIMIT 10;`",
          "- **Sonuç:** `B-GENEL-01`", "",
          "#### B-GENEL-02 · Gönderilmiş bildirim değiştirilemez",
          "- **Hesap:** — (veritabanı kuralı)",
          "- **Adım:** Adminer'de `SELECT tgname FROM pg_trigger WHERE tgrelid = 'notifications'::regclass AND NOT tgisinternal;`",
          "- **Beklenen:** `notifications_sent_final` ve `notifications_active_property` listede",
          "- **Sonuç:** `B-GENEL-02`", "",
          "#### B-GENEL-03 · Kanal durumları dürüst",
          "- **Hesap:** —",
          "- **Adım:** `SELECT channel, status, provider, count(*) FROM notifications GROUP BY 1,2,3 ORDER BY 1,2;`",
          "- **Beklenen:** IN_APP → SENT/in_app; SMS → SENT/netgsm (SMS kutusunda karşılığı var); EMAIL → SENT/smtp (Mailpit'te karşılığı var) ya da e-postası olmayanlar için SUPPRESSED/FAILED gerekçeli; PUSH → PENDING (sağlayıcı yok). `SENT` olup sağlayıcısı boş satır OLMAMALI",
          "- **Sonuç:** `B-GENEL-03`", "",
          "#### B-GENEL-04 · Bildirim tercihleri",
          "- **Hesap:** KİRACI",
          "- **Adım:** Sakin uygulamasında bildirim tercihlerinden bir kanalı/konuyu kapat; o konuda bildirim üreten bir işlem yaptır (ör. yöneticinin duyurusu)",
          "- **Beklenen:** kapatılan kanal için satır `SUPPRESSED` ve gerekçeli; açık kanallar normal",
          "- **Sonuç:** `B-GENEL-04`", ""]
    o += ["## 6.2 İşlemle üretilen bildirimler (uç bazında)", "",
          "Her satır bir test ID'sidir. Önce **Tetikleyen** sütunundaki işlemi ilgili sayfadan yapın (sayfa bölümündeki test ID'si de geçer), sonra alıcıları doğrulayın.", ""]
    rows = [r for r in H["routes"] if (r.get("topics") or r.get("audience")) and not r.get("dead")]
    for r in rows:
        nid = uniq("B-" + slug(r["key"].replace("/", " ")))
        txt, accs = audience_text(r)
        trig = sorted(set(place(c) for c in CONS.get(r["key"], [])))
        o.append("#### %s · `%s`" % (nid, r["key"]))
        o.append("- **Tetikleyen:** %s" % (", ".join(trig) if trig else "arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir"))
        o.append("- **Konu:** %s · **Servis:** %s (`%s`)" % (", ".join("`%s`" % t for t in r["topics"] or ["?"]), r["svc"], r["where"]))
        o.append("- **Alıcı:** %s" % txt)
        if accs:
            o.append("- **Görmesi gerekenler:** %s" % "; ".join("%s → %s" % (a, inbox_of(a)) for a in accs))
            others = [a for a in ACC if a not in accs and a != "SİTE_B"]
            o.append("- **Görmemesi gerekenler:** %s ve her durumda SİTE_B" % ", ".join(others))
        o.append("- **Sorgu:** `%s`" % q_notif(r["topics"] or ["%"]))
        o.append("- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez")
        o.append("- **Sonuç:** `%s`" % nid)
        o.append("")
    o += ["## 6.3 Zamanlanmış işler (`cmd/scheduler`, test ortamında dakikada bir)", "",
          "Koşulu arayüzden oluşturun, **en az 1 dakika** bekleyin, sonra bildirimleri ve zamanlayıcı günlüğünü (http://localhost:18000/gunluk?s=scheduler) kontrol edin. "
          "Aynı koşul ikinci turda yeniden bildirim üretmemeli (DedupeKey).", ""]
    jobs = [
        ("dues.overdue", "Vadesi geçmiş, ödenmemiş aidat (seed'de geçmiş aylar var; yoksa Aidat sayfasından son ödeme tarihi geçmiş tahakkuk)", "borcun sorumlusu; kiracı sorumluysa malik de ayrıca (`dues.overdue.tenant`)", "KİRACI ve MALİK_A4 (A-4), YÖNETİCİ (A-3) — dairesine göre", "`dues.overdue%`"),
        ("contract.notice", "Sözleşmeler: bitişi yakın sözleşme ekle — bitiş tarihi bugünden 30 gün sonra, ihbar süresi 30 gün (ihbar son günü 14 gün içinde kalmalı)", "yönetim", "YÖNETİCİ, KURUL, DENETÇİ", "`contract.notice%`"),
        ("contract.expired", "Sözleşmeler: bitiş tarihi dün olan ve durumu ACTIVE sözleşme ekle", "yönetim", "YÖNETİCİ, KURUL, DENETÇİ", "`contract.expired%`"),
        ("patrol.overdue", "Devriye: bir tur başlat (Yön.mobil, GÖREVLİ) ve beklenen süre + toleransı aşacak kadar açık bırak (rota süresi 2 dk, tolerans 1 dk yapılabilir)", "yönetim", "YÖNETİCİ, KURUL, DENETÇİ", "`patrol.overdue%`"),
        ("asset.maintenance", "Demirbaş: sonraki bakım tarihi 14 gün içinde ya da geçmiş demirbaş ekle", "yönetim", "YÖNETİCİ, KURUL, DENETÇİ", "`asset.maintenance%`"),
        ("kvkk.due", "KVKK başvurusu (sakin uygulaması) — yanıt süresi 5 gün içinde dolan açık başvuru gerekir; yeni başvuru 30 gün sürelidir, bu yüzden genelde ATLANDI (zaman gerektirir). Not düş.", "yönetim", "YÖNETİCİ, KURUL, DENETÇİ", "`kvkk.due%`"),
        ("budget.approval", "Yönetişim: geçici işletme projesini bildir (NOTIFIED); genel kurul onay son günü yakınsa uyarır — tarih yakın değilse ATLANDI", "yönetim", "YÖNETİCİ, KURUL, DENETÇİ", "`budget.approval%`"),
        ("emergency.drill", "Acil durum: hiç tatbikat kaydı yokken personel kaydı ekle (Personel sayfası)", "yönetim", "YÖNETİCİ, KURUL, DENETÇİ", "`emergency.drill%`"),
        ("compliance.employer", "Ayarlar: MUHSGK takvimi açık; personel işe giriş/çıkış SGK süresi 5 gün içinde olan kayıt", "yönetim", "YÖNETİCİ, KURUL, DENETÇİ", "`compliance%`"),
        ("kvkk.destruction", "Ayarlar → saklama süreleri: süre tanımsızsa hatırlatma; süre tanımlı ve süresi dolmuş kayıt varsa anonimleştirme", "yönetim", "YÖNETİCİ, KURUL, DENETÇİ", "`kvkk.destruction%`"),
        ("dask.renewal", "Sigorta: bitişi 30 gün içinde olan DASK poliçesi gir (ör. B-1)", "dairenin malik/vekili", "MALİK_B1, VEKİL_B1", "`dask%`"),
        ("activity.purge", "Bildirim üretmez; saklama süresi dolan istemci etkinlik kayıtlarını siler", "—", "—", None),
        ("sensor.purge", "Bildirim üretmez; 365 günden eski sensör okumalarını siler (cihaz simülatöründe eski tarihli okuma gönderilerek denenebilir)", "—", "—", None),
        ("patrol.track.purge", "Bildirim üretmez; 1 yıldan eski devriye konum izini siler", "—", "—", None),
    ]
    for j, cond, aud, accs, tp in jobs:
        jid = "B-ZAMAN-" + slug(j)
        o.append("#### %s · `%s`" % (jid, j))
        o.append("- **Koşulu oluştur:** %s" % cond)
        o.append("- **Alıcı:** %s · **Görmesi gerekenler:** %s" % (aud, accs))
        if tp:
            o.append("- **Sorgu:** `SELECT created_at, topic, channel, status, recipient_address, subject, dedupe_key FROM notifications WHERE topic LIKE %s ORDER BY created_at DESC LIMIT 30;`" % ("'%s'" % tp.strip("`")))
            o.append("- **Beklenen:** 1-2 dk içinde bildirim; aynı `dedupe_key` ile ikinci satır YOK; metin tarihleri gg.aa.yyyy biçiminde")
        else:
            o.append("- **Beklenen:** zamanlayıcı günlüğünde iş hatasız çalışmış (`[scheduler]` satırları); silinmemesi gereken kayıtlar duruyor")
        o.append("- **Sonuç:** `%s`" % jid)
        o.append("")
    o += ["## 6.4 Servis içi bekçiler", "",
          "#### B-BEKCI-SENSOR · Sensör sinyal kesintisi",
          "- **Hesap:** YÖNETİCİ (panel Sensörler) + cihaz simülatörü",
          "- **Adım:** Panelde sensör ekle (çevrimdışı sayılma süresi 2 dk); gösterilen cihaz anahtarını kopyala; http://localhost:18000/cihaz ile bir okuma gönder; 3 dk bekle",
          "- **Beklenen:** önce sensör ÇEVRİMİÇİ ve okuma listede; süre dolunca OFFLINE alarmı açılır, `iot.offline` bildirimi YÖNETİCİ, KURUL, GÖREVLİ'ye gider; yeni okuma gelince alarm kapanır/iyileşir",
          "- **Sorgu:** `SELECT kind, status, opened_at, closed_at FROM sensor_alerts ORDER BY xmin::text::bigint DESC LIMIT 5;`",
          "- **Sonuç:** `B-BEKCI-SENSOR`", "",
          "#### B-BEKCI-ESIK · Sensör eşik aşımı",
          "- **Adım:** Sıcaklık sensörüne üst eşik 30 ver; simülatörden 45 gönder; sonra 25 gönder",
          "- **Beklenen:** HIGH alarmı açılır ve bildirim gider; normal değer alarmı kendiliğinden kapatmaz (yönetici onaylar/kapatır) — ekrandaki davranışı gözleme yaz",
          "- **Sonuç:** `B-BEKCI-ESIK`", "",
          "#### B-BEKCI-CIHAZ · Geçiş cihazı canlılığı",
          "- **Hesap:** YÖNETİCİ (panel Otopark → geçiş cihazları) + cihaz simülatörü (tür: geçiş cihazı)",
          "- **Adım:** Cihaz ekle; anahtarla bir sinyal gönder; sinyali kes ve bekle (30 sn aralıkla denetlenir, cihazın tolerans süresi kadar); sonra yeniden sinyal gönder",
          "- **Beklenen:** sinyal kesilince olay açılır ve `device.offline` (YÖNETİCİ, KURUL, GÖREVLİ); sinyal gelince `device.recovered`",
          "- **Sonuç:** `B-BEKCI-CIHAZ`", "",
          "#### B-BEKCI-KART · Kart ödemesi uzlaştırma",
          "- **Hesap:** KİRACI (sakin uygulaması)",
          "- **Adım:** Kartla ödeme başlat; sahte iyzico sayfasında \"Yarıda bırak\" seç; 20+ dk sonra (ya da ödemeyi başarıyla tamamlamadan bırakıp) ödeme durumuna bak",
          "- **Beklenen:** ödeme askıda sonsuza kadar kalmaz; uzlaştırma bekçisi sonucu sahte iyzico'dan yeniden sorgular (iyzico kayıtlarında `detail` çağrıları)",
          "- **Sonuç:** `B-BEKCI-KART`", "",
          "#### B-BEKCI-KARGO · Kargo kanıtı imhası",
          "- **Adım:** Teslim kanıtı (imza/fotoğraf) olan kargo kaydının saklama süresi dolunca/silinince kanıt dosyası depodan silinir — 15 dk'da bir",
          "- **Beklenen:** `SELECT count(*) FROM storage_deletion_queue;` işlendikten sonra azalır; genelde ATLANDI (süre gerektirir)",
          "- **Sonuç:** `B-BEKCI-KARGO`", ""]
    open(os.path.join(OUT, "06-bildirimler.md"), "w").write("\n".join(o))
    return len(rows)


# ---------------- VERİTABANI ----------------
def write_db():
    o = section_header("7. Veritabanı kuralları ve bütünlük",
                       "Adminer (http://localhost:18080, `test_okuyucu`) salt okunurdur: buradan veri DEĞİŞTİRİLEMEZ, bu bilerek böyledir. "
                       "Tetikleyicilerin engellediği işlemler arayüzden denenir; arayüz anlaşılır bir hata göstermeli, veri değişmemelidir.")
    o += ["## 7.1 Tetikleyiciler", "", "| ID | Tablo | Tetikleyici | Ne zaman | Etki / engel | Nasıl denenir |", "|---|---|---|---|---|---|"]
    for t in TRIG:
        tid = "T-" + slug(t["name"])
        eff = ", ".join(t["writes"]) if t["writes"] else ""
        if t["raises"]:
            eff = (eff + " · " if eff else "") + "engeller: " + t["raises"][0].replace("|", "/")
        how = "ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli" if t["raises"] else "ilgili işlemi yap → `%s` sonucu Adminer'de görünmeli" % (eff or "satır düzenlemesi")
        o.append("| %s | `%s` | `%s` | %s | %s | %s |" % (tid, t["table"], t["name"], t["when"], eff or "satırı düzenler", how))
    o += ["", "## 7.2 Bütünlük sorguları (testlerin sonunda çalıştırın)", ""]
    checks = [
        ("D-RLS", "RLS açık tablolar", "SELECT count(*) FILTER (WHERE relrowsecurity) AS rls_acik, count(*) AS toplam FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relkind = 'r';", "rls_acik = 129 (bilerek dışarıda 10 tablo)"),
        ("D-PARA", "Ödenen tutar tahakkuku aşmaz", "SELECT id, total_amount, paid_amount FROM monthly_assessments WHERE paid_amount > total_amount;", "0 satır"),
        ("D-ODEME", "Onaylı ödemenin dağıtımı tutarına eşit", "SELECT p.id, p.amount, sum(pa.amount) FROM payments p JOIN payment_assessments pa ON pa.payment_id = p.id WHERE p.status = 'COMPLETED' GROUP BY 1,2 HAVING sum(pa.amount) <> p.amount;", "0 satır"),
        ("D-DEFTER", "Tahsilat defteri zinciri", "SELECT count(*) FROM finance_ledger;", "panelde/sakin uygulamasında \"Tahsilat kayıtlarını doğrula\" zincir sağlam demeli; sayı ödeme işlemleriyle artmış olmalı"),
        ("D-KARAR", "Karar defteri değişmez", "SELECT count(*) FROM book_entries;", "kayıt eklenmiş; düzenleme/silme arayüzde yok ya da reddediliyor"),
        ("D-AUDIT", "İşlem kaydı eksiksiz", "SELECT source, action, count(*) FROM audit_logs GROUP BY 1,2 ORDER BY 1,2;", "API satırları her işlem türü için var; DENIED satırları yetki testlerinde oluşmuş; CLIENT satırları (ekran gezintisi) site ayarındaki düzeye göre"),
        ("D-KISI", "Personel kişisel verisi şifreli", "SELECT first_name, tc_number, tc_number_encrypted IS NOT NULL AS tc_sifreli, bank_iban, bank_iban_encrypted IS NOT NULL AS iban_sifreli, bank_iban_last4 FROM employees;", "personel eklendiyse `tc_number` ve `bank_iban` BOŞ (NULL), şifreli sütunlar dolu; ekranda yalnız maskeli (son 4 hane) görünür"),
        ("D-SAKIN", "Ayrılan sakine bildirim gitmez", "SELECT u.phone, ru.is_active, ru.end_date FROM resident_units ru JOIN users u ON u.id = ru.resident_id ORDER BY ru.end_date NULLS FIRST;", "pasifleştirilen sakin sonraki toplu bildirimlerin alıcısı değil (6. bölüm sorgularıyla karşılaştır)"),
        ("D-SITE", "Her kayıt doğru sitede", "SELECT property_id, count(*) FROM notifications GROUP BY 1;", "Deniz Apartmanı satırları yalnız o sitedeki işlemlerden"),
    ]
    for cid, name, q, exp in checks:
        o += ["#### %s · %s" % (cid, name), "- **Sorgu:** `%s`" % q, "- **Beklenen:** %s" % exp, "- **Sonuç:** `%s`" % cid, ""]
    o += ["Not: sorgudaki bir sütun adı şemada farklıysa Adminer hata verir; o durumda tabloyu Adminer'de açıp ilgili sütunu bulun ve gözleme yazın (KALDI değil, sorgu düzeltilir).", ""]
    open(os.path.join(OUT, "07-veritabani.md"), "w").write("\n".join(o))


def write_unused():
    o = section_header("9. Arayüzü olmayan uçlar ve bilinen sınırlar",
                       "Bunlar tarayıcıdan denenemez; burada yalnız beklenen durumları listelenir. Ekranlarda bunlara bağlı düğme GÖRÜNMEMELİ.")
    used = set(CONS)
    o += ["| Uç | Servis | Not |", "|---|---|---|"]
    notes = {"GET /public/clearance/:code": "borcu yoktur belgesindeki karekod → `http://localhost:3001/dogrula/<kod>` (01 bölümünde test edilir)",
             "POST /auth/refresh": "jeton yenileme; oturum 15 dk sonra da sürüyorsa çalışıyor demektir (01 bölümü)",
             "POST /public/payments/iyzico/callback": "sahte iyzico sayfası çağırır (kart ödemesi senaryosu)",
             "POST /public/devices/heartbeat": "cihaz simülatörü (http://localhost:18000/cihaz)",
             "POST /public/sensors/data": "cihaz simülatörü (http://localhost:18000/cihaz)"}
    for k, r in sorted(ROUTES.items()):
        if k in used or r.get("dead"):
            continue
        o.append("| `%s` | %s | %s |" % (k, r["svc"], notes.get(k, "arayüzde karşılığı yok")))
    dead = sorted(k for k, r in ROUTES.items() if r.get("dead"))
    o += ["", "**Yazılmamış modül (S-07):** `banking` — %d uç, hepsi 501 döner. Panelde banka entegrasyonu menüsü varsa \"henüz hazır değil\" demeli." % len(dead),
          "", "**Bilinen sınırlar:** push bildirimi yok (PUSH kanalı PENDING kalır); iOS derlemesi yok; web derlemesinde biyometrik giriş yok; "
          "QR okutma ve konum web'de tarayıcı iznine bağlıdır.", ""]
    open(os.path.join(OUT, "09-arayuzsuz-ve-sinirlar.md"), "w").write("\n".join(o))


os.makedirs(OUT, exist_ok=True)
write_roles()
pfiles, ptotal = write_panel()
st = write_mobile("mobile", "04-sakin-uygulamasi.md", "4. Sakin uygulaması (web) — ekran ekran", SAKIN, "S", "MALİK_B1", SAKIN_ACC)
yt = write_mobile("admin_app", "05-yonetici-uygulamasi.md", "5. Yönetici uygulaması (web) — ekran ekran", YON, "Y", "YÖNETİCİ", YON_ACC)
nt = write_notifications()
write_db()
write_unused()

order = ["00-baslangic.md", "01-oturum-ve-hesap.md", "02-rol-ve-izolasyon.md"] + [f for f, _, _ in pfiles] + \
        ["04-sakin-uygulamasi.md", "05-yonetici-uygulamasi.md", "06-bildirimler.md", "07-veritabani.md", "08-uctan-uca-senaryolar.md", "09-arayuzsuz-ve-sinirlar.md", "10-usta-hizmet.md"]
parts = []
for f in order:
    p = os.path.join(OUT, f)
    if os.path.exists(p):
        parts.append(open(p, encoding="utf-8").read().replace(GEN, "").strip())
open(os.path.join(OUT, "TEST-PLANI-TAMAMI.md"), "w").write(
    "# SiteEksen tarayıcı test planı — tamamı\n\n> Bütün bölümlerin tek dosyada birleşimi (üretilir). Bölüm bölüm çalışmak için [README.md](README.md).\n\n"
    + "\n\n---\n\n".join(parts) + "\n")
ids = sum(open(os.path.join(OUT, f), encoding="utf-8").read().count("\n#### ") for f in order if os.path.exists(os.path.join(OUT, f)))
json.dump({"panel_dosyalari": [[f, t, n] for f, t, n in pfiles], "panel_eylem": ptotal, "sakin_eylem": st, "yonetici_eylem": yt,
           "bildirim_ucu": nt, "test_basligi": ids}, open(os.path.join(S, "test_plani.json"), "w"), ensure_ascii=False)
print(json.dumps({"panel_eylem": ptotal, "sakin_eylem": st, "yonetici_eylem": yt, "bildirim_ucu": nt, "test_basligi": ids}, ensure_ascii=False))
