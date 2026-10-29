#!/usr/bin/env python3
import os, re, sys, json

REPO, S, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
J = lambda n: json.load(open(os.path.join(S, n)))
cg, cons, trig, panel_ep = J("cg.json"), J("consumers.json"), J("triggers.json"), J("panel_ep.json")
TABLES = set()
for _f in os.listdir(os.path.join(REPO, "backend/migrations")):
    if _f.endswith(".sql"):
        TABLES |= set(x.lower() for x in re.findall(r"CREATE\s+(?:TABLE|(?:OR\s+REPLACE\s+)?VIEW|MATERIALIZED\s+VIEW)\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:public\.)?(\w+)", open(os.path.join(REPO, "backend/migrations", _f), encoding="utf-8").read(), re.I))
for _r in cg:
    _r["Writes"] = [w for w in (_r["Writes"] or []) if w.split(" ", 1)[1] in TABLES]
    _r["Reads"] = [w for w in (_r["Reads"] or []) if w in TABLES]
ROLE_TR = {"Manager": "MANAGER", "BoardMember": "BOARD_MEMBER", "Auditor": "AUDITOR", "Staff": "STAFF", "Owner": "OWNER", "Resident": "RESIDENT", "Tenant": "TENANT", "SuperAdmin": "SUPER_ADMIN"}
CHECK_DEF = {}
for root, _, fns in os.walk(os.path.join(REPO, "backend", "services")):
    for fn in fns:
        if fn.endswith(".go") and not fn.endswith("_test.go"):
            p = os.path.join(root, fn)
            for i, l in enumerate(open(p, encoding="utf-8")):
                m = re.match(r"^func (isManagement|isFinanceManager|hasRole|hasAnyRole|isManager|isManagementRole|canManage|residentScope|reportRoles)\(", l)
                if m:
                    CHECK_DEF.setdefault(m.group(1), []).append("%s:%d" % (os.path.relpath(p, REPO), i + 1))
SVC_OF = {}
for r in cg:
    SVC_OF.setdefault(r["Svc"], []).append(r)
    aud = [a for a in (r["Audience"] or []) if a != "belirli kişi: {to}"]
    r["Audience"] = [("işlemin muhatabı (" + a.split(": ", 1)[1].replace("{", "").replace("}", "") + ")") if a.startswith("belirli kişi") else a for a in aud]
trig_by_table = {}
for t in trig:
    trig_by_table.setdefault(t["table"], []).append(t)
COMMON = {"units", "users", "resident_units", "properties", "property_roles", "legal_parameters", "unit_occupancy"}


def match(verb, path):
    path = re.sub(r"\$\{[^}]+\}|\$\w+", ":p", path).split("?")[0]
    segs = [x for x in path.strip("/").split("/") if x]
    for strict in (True, False):
        best, score = None, -1
        for r in cg:
            if r["Method"] not in (verb, "Any"):
                continue
            rs = r["Path"].strip("/").split("/")
            if len(rs) != len(segs):
                continue
            if all(a == b or a.startswith(":") or (not strict and ":p" in b) for a, b in zip(rs, segs)):
                sc = sum(a == b for a, b in zip(rs, segs))
                if sc > score:
                    best, score = r, sc
        if best:
            return best
    return None


for _fn, _tag in (("mobile_outline.txt", "Sakin "), ("adminapp_outline.txt", "Yönetici-mobil ")):
    _cur = None
    for _l in open(os.path.join(S, _fn), encoding="utf-8"):
        if _l.startswith("## "):
            _cur = _tag + os.path.basename(_l[3:].strip()).replace(".dart", "")
            continue
        for _v, _p in re.findall(r"(GET|POST|PUT|PATCH|DELETE) (/\S+?)(?:,|$)", _l.strip()):
            _r = match(_v, _p)
            if _r and _cur:
                _k = _r["Method"] + " " + _r["Path"]
                cons.setdefault(_k, [])
                if _cur not in cons[_k]:
                    cons[_k].append(_cur)

readers = {}
for r in cg:
    if r["Method"] == "GET":
        for t in r["Reads"] or []:
            readers.setdefault(t, []).append(r["Method"] + " " + r["Path"])


def short(who):
    return who.replace("Panel /dashboard", "Panel").replace("Panel /", "Panel ").replace("Yönetici-mobil ", "Yön.mobil ").replace("_screen", "")


def seen_in(r):
    tabs = set(w.split(" ", 1)[1] for w in (r["Writes"] or []))
    tabs -= {"audit_logs"}
    places = set()
    for t in tabs:
        for rk in readers.get(t, []):
            for who in cons.get(rk, []):
                places.add(short(who))
    return sorted(places)


def roles_of(r):
    parts = []
    if r["Roles"]:
        parts.append("/".join(ROLE_TR.get(x, x) for x in r["Roles"]))
    for c in r["Checks"] or []:
        parts.append("işleyicide `%s` (%s)" % (c, ", ".join(CHECK_DEF.get(c, ["?"])[:1])))
    for f in r["SQLFuncs"] or []:
        if f in ("resident_can_use", "assessment_visible_to"):
            parts.append("`%s`" % f)
    if not parts and r.get("RoleRefs"):
        parts.append("serviste rol karşılaştırması: " + "/".join(r["RoleRefs"]))
    return "; ".join(parts) or "oturum açmış herkes (site kapsamı)"


def writes_of(r):
    w = [x.split(" ", 1)[1] + ("(+)" if x.startswith("INSERT") else "(±)" if x.startswith("UPDATE") else "(−)") for x in (r["Writes"] or []) if "audit_logs" not in x]
    trs = []
    for x in r["Writes"] or []:
        t = x.split(" ", 1)[1]
        for tr in trig_by_table.get(t, []):
            if tr["name"] not in trs:
                trs.append(tr["name"])
    s = ", ".join(w) or "—"
    if trs:
        s += " · tetikleyici: " + ", ".join(trs)
    if r.get("Storage"):
        s += " · dosya deposu"
    return s


def notif_of(r):
    if not r["Topics"] and not r["Audience"]:
        return "yok"
    aud = [a for a in r["Audience"] or [] if a != "NotifyCharges"]
    if "NotifyCharges" in (r["Audience"] or []):
        aud.append("AssessmentPayers")
    tps = [t if "(…)" not in t else t[:t.find("{")] + "{…}" for t in r["Topics"] or ["?"]]
    return "%s → %s" % (", ".join("`%s`" % t for t in tps), ", ".join(sorted(set(aud))) or "işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta")


def row(n, label, calls):
    cells = []
    for c in calls:
        r = c if isinstance(c, dict) else None
        if r is None:
            cells.append(("`%s` — backend'de karşılığı yok" % c, "", "", "", ""))
            continue
        key = "%s %s" % (r["Method"], r["Path"])
        if r["Svc"] in ("banking", "meeting_wizard"):
            cells.append(("`%s` (%s) — **501, yazılmadı**" % (key, r["Svc"]), "", "", "", ""))
            continue
        cells.append(("`%s` · %s · `%s`" % (key, r["Svc"], r["Where"]), roles_of(r), writes_of(r), notif_of(r),
                      ", ".join(seen_in(r)) if r["Method"] != "GET" else "—"))
    if not cells:
        return "| %s | %s | — | | | | |" % (n, label)
    lines = []
    for i, c in enumerate(cells):
        lines.append("| %s | %s | %s | %s | %s | %s | %s |" % (n if i == 0 else "", label if i == 0 else "↳", *c))
    return "\n".join(lines)


HEAD = "| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |\n|---|---|---|---|---|---|---|"


def route_info(r):
    if not isinstance(r, dict):
        return {"key": r, "missing": True}
    key = "%s %s" % (r["Method"], r["Path"])
    return {"key": key, "method": r["Method"], "path": r["Path"], "svc": r["Svc"], "where": r["Where"], "roles": roles_of(r),
            "role_list": [ROLE_TR.get(x, x) for x in r.get("Roles") or []], "writes": [w for w in (r.get("Writes") or []) if "audit_logs" not in w],
            "writes_text": writes_of(r), "topics": r.get("Topics") or [], "audience": r.get("Audience") or [], "notif": notif_of(r),
            "seen": seen_in(r) if r["Method"] != "GET" else [], "reads": r.get("Reads") or [], "storage": bool(r.get("Storage")), "dead": r["Svc"] in ("banking", "meeting_wizard"),
            "triggers": sorted(set(tr["name"] for w in (r.get("Writes") or []) for tr in trig_by_table.get(w.split(" ", 1)[1], [])))}


def parse_outline(fn):
    blocks, cur = {}, None
    for l in open(os.path.join(S, fn), encoding="utf-8"):
        l = l.rstrip("\n")
        if l.startswith("## "):
            cur = l[3:]
            blocks[cur] = []
        elif l and cur:
            blocks[cur].append(l)
    return blocks


def esc(s):
    return s.replace("|", "\\|")


# ---------------- PANEL ----------------
pol = parse_outline("panel_outline.txt")
rbac = open(os.path.join(REPO, "admin/src/lib/rbac.ts"), encoding="utf-8").read()
consts = {"MANAGEMENT": ["MANAGER", "BOARD_MEMBER"], "MANAGEMENT_AND_AUDIT": ["MANAGER", "BOARD_MEMBER", "AUDITOR"], "MANAGEMENT_AND_STAFF": ["MANAGER", "BOARD_MEMBER", "STAFF"]}
rules = []
for m in re.finditer(r"\{\s*prefix:\s*\"([^\"]+)\",\s*roles:\s*(\[[^\]]*\]|\w+),\s*reason:\s*\"([^\"]+)\"", rbac):
    rs = m.group(2)
    if rs in consts:
        roles = consts[rs]
    else:
        roles = []
        for x in re.findall(r"\.\.\.(\w+)|Roles\.(\w+)", rs):
            roles += consts.get(x[0], []) if x[0] else [ROLE_TR.get(x[1], x[1])]
    rules.append((m.group(1), roles, m.group(3)))


def panel_roles(url):
    best = None
    for p, r, why in rules:
        if url == p or url.startswith(p + "/"):
            if not best or len(p) > len(best[0]):
                best = (p, r, why)
    return best


side = open(os.path.join(REPO, "admin/src/components/layout/sidebar.tsx"), encoding="utf-8").read()
menu, sec = {}, ""
for l in side.split("\n"):
    m = re.search(r"title:\s*\"([^\"]*)\"", l)
    if m and "items" in l or (m and "title" in l and "name" not in l):
        sec = m.group(1) if m else sec
    for n, h in re.findall(r"name:\s*\"([^\"]+)\",\s*href:\s*\"([^\"]+)\"", l):
        menu[h] = (sec or "Üst", n)
menu["/dashboard/settings"] = ("Kenar çubuğu altı", "Ayarlar")

comp_imports = {}
for k in pol:
    if k.endswith("page.tsx"):
        src = open(os.path.join(REPO, "admin/src", k), encoding="utf-8").read()
        comp_imports[k] = re.findall(r"from\s+\"@/components/([\w/-]+)\"", src)


def panel_calls(names):
    out = []
    for n in names:
        for c in panel_ep.get(n, []):
            r = match(c["verb"], c["path"])
            if r:
                out.append(r)
            elif c["path"].startswith("/dashboard"):
                out.append({"Method": c["verb"], "Path": c["path"], "Svc": "gateway", "Where": "backend/cmd/gateway/main.go", "Roles": [], "Checks": [], "SQLFuncs": [], "Writes": [], "Topics": [], "Audience": [], "Storage": False})
            else:
                out.append("%s %s" % (c["verb"], c["path"]))
    return out


STRUCT = {"panel": [], "mobile": [], "admin_app": []}
LAST = []


def render_items(lines, callres):
    view, acts = [], []
    del LAST[:]
    n = 0
    comp = ""
    for l in lines:
        cm = re.match(r"0 CARD \[bileşen `([^`]+)`\]", l)
        if cm:
            comp = cm.group(1).split("/")[-1].replace(".tsx", "")
            view.append("- **Bileşen `admin/src/%s`** (aşağıdaki satır numaraları bu dosyaya aittir)" % cm.group(1))
            continue
        m = re.match(r"(\d+) (\S+) ?(.*?)(?: ⇒ (.*))?$", l)
        if not m:
            continue
        line, kind, desc, calls = m.group(1), m.group(2), m.group(3), m.group(4)
        names = [x.strip() for x in calls.split(",")] if calls else []
        if kind in ("DÜĞME", "FORM", "DEĞİŞİMDE", "SEÇİM") and (names or kind in ("DÜĞME", "SEÇİM")):
            if not names:
                desc = desc + " — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok"
            n += 1
            desc = desc.replace("None — ", "(başlık dinamik) — ")
            desc = re.sub(r"açar: [\w,]+", "pencere/form açar", desc)
            desc = desc.replace("; pencere/form açar) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok", "; pencere/form açar)").replace("(pencere/form açar) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok", "(pencere/form açar)")
            label = "%s **%s** (%ssatır %s)" % ({"DÜĞME": "Düğme", "FORM": "Form", "DEĞİŞİMDE": "Seçim", "SEÇİM": "Seçim"}[kind], esc(desc) or "—", (comp + " ") if comp else "", line)
            rs = callres(names)
            acts.append(row(n, label, rs))
            LAST.append({"n": n, "kind": kind, "desc": desc, "line": int(line), "comp": comp, "calls": [route_info(r) for r in rs]})
        elif kind == "OKUR":
            rs = [r for r in callres(names)]
            view.append("- Veri (satır %s): %s" % (line, "; ".join("`%s %s` (%s)" % (r["Method"], r["Path"], r["Svc"]) if isinstance(r, dict) else "`%s` (karşılığı yok)" % r for r in rs)))
        elif kind in ("TABLO",):
            view.append("- Tablo (satır %s): %s" % (line, esc(desc) or "(sütunlar dinamik)"))
        elif kind in ("SEKMELER", "SEKME"):
            view.append("- Sekmeler (satır %s): %s" % (line, esc(desc)))
        elif kind in ("CARD", "MODAL", "DİYALOG", "BAŞLIK"):
            view.append("- %s (satır %s): %s" % ({"CARD": "Kart", "MODAL": "Pencere", "DİYALOG": "Pencere", "BAŞLIK": "Başlık"}[kind], line, esc(desc)))
        elif kind == "NOT":
            view.append("- Bilgi notu (satır %s): %s" % (line, esc(desc)))
        elif kind in ("BAĞLANTI",):
            view.append("- Bağlantı (satır %s): %s" % (line, esc(desc)))
        elif kind in ("DOSYA",):
            view.append("- Dosya seçme (satır %s)" % line)
        elif kind == "ALAN":
            view.append("- Alan (satır %s): %s" % (line, esc(desc)))
        elif kind == "MESAJ":
            view.append("- Mesaj (satır %s): %s" % (line, esc(desc)))
    return view, acts


def write_panel():
    o = ["# 1. Yönetim paneli (Next.js) — sayfa sayfa", "",
         "Kaynak: `admin/src/app/**/page.tsx` ve içe aktardığı `admin/src/components/**`. Sayfa yetkisi `admin/src/lib/rbac.ts` (panel) — asıl denetim backend'dedir (tablodaki *Yetki* sütunu). `canWrite` = MANAGER veya BOARD_MEMBER (`admin/src/lib/use-api.ts:78`); AUDITOR yalnız okur.", ""]
    order = []
    for k in sorted(pol):
        if not k.endswith("page.tsx"):
            continue
        url = "/" + k.replace("app/", "", 1).replace("(dashboard)/", "").rsplit("/page.tsx", 1)[0]
        url = "/" if url == "/page.tsx" or url == "/app" else url
        order.append((menu.get(url, ("Menü dışı", ""))[0], url, k))
    sec_order = ["Üst", "Sakinler ve İletişim", "Mali", "Yönetişim (KMK)", "Operasyon", "Analiz", "Sistem", "Kenar çubuğu altı", "Menü dışı"]
    order.sort(key=lambda x: (sec_order.index(x[0]) if x[0] in sec_order else 99, x[1]))
    cur = None
    total = 0
    for sec, url, k in order:
        if sec != cur:
            o += ["", "## %s" % sec, ""]
            cur = sec
        pr = panel_roles(url)
        o.append("### %s — `%s`" % (menu.get(url, ("", url))[1] or url, url))
        o.append("- **Dosya:** `admin/src/%s`" % k)
        o.append("- **Panel erişimi:** %s" % ("%s — %s" % ("/".join(pr[1]), pr[2]) if pr else "herkese açık / oturum gerekmez (rbac kapsamı dışı)"))
        lines = list(pol[k])
        for ci in comp_imports.get(k, []):
            ck = "components/%s.tsx" % ci
            if ck in pol and not ci.startswith("ui/"):
                lines += ["0 CARD [bileşen `%s`]" % ck] + pol[ck]
        view, acts = render_items(lines, panel_calls)
        STRUCT["panel"].append({"section": sec, "title": menu.get(url, ("", url))[1] or url, "url": url, "file": "admin/src/" + k,
                                "access": pr[1] if pr else None, "access_reason": pr[2] if pr else "", "view": view, "actions": list(LAST)})
        if view:
            o.append("- **Ekranda:**")
            o += ["  " + v for v in view]
        if acts:
            total += len(acts)
            o += ["", HEAD] + acts
        else:
            o.append("- **Eylem:** yok (salt bilgi / yönlendirme)")
        o.append("")
    lay = ["components/layout/sidebar.tsx", "components/layout/header.tsx"]
    o += ["## Her sayfada ortak: kenar çubuğu ve üst bar", "",
          "| Öğe | Ne yapar | Uç |", "|---|---|---|",
          "| Aktif site seçici (`sidebar.tsx`) | Siteyi değiştirir, yeni siteye ait jeton alınır, `/dashboard`'a döner | `POST /users/me/active-property`, `POST /auth/refresh`; liste: `GET /users/me/properties` |",
          "| + Yeni Taşınmaz Ekle (`sidebar.tsx`) | Form: Ad*, Adres*, Şehir*, İlçe, Tür (Site/Apartman/Bina) → oluşturur ve o siteye geçer | `POST /users/me/properties` |",
          "| Menü öğeleri | Aktif sitedeki rollere göre süzülür (`canAccess`) | — |",
          "| Ayarlar bağlantısı | Yalnız MANAGER/BOARD_MEMBER görür | — |",
          "| Menü düğmesi (mobil genişlik) | Kenar çubuğunu çekmece olarak açar/kapatır | — |",
          "| Zil simgesi (`notification-bell.tsx`) | Okunmamış sayısını gösterir (60 sn'de bir yenilenir); açılınca son 10 bildirim; bildirime tıklamak okundu sayar; \"Tümünü okundu say\"; \"Tümünü gör\" → `/dashboard/inbox` | `GET /notifications/unread-count`, `GET /notifications?channel=IN_APP&limit=10`, `POST /notifications/:id/read`, `POST /notifications/read-all` |",
          "| Kullanıcı menüsü → Şifre değiştir | `/dashboard/account` | — |",
          "| Kullanıcı menüsü → Çıkış Yap (`header.tsx:148`) | Sunucuda jetonları iptal eder, iptal edilemezse uyarır, oturumu kapatır | `POST /auth/logout` |",
          ""]
    open(os.path.join(OUT, "01-panel.md"), "w").write("\n".join(o))
    return total, len(order)


# ---------------- MOBİL ----------------
def mobile_calls(names):
    out = []
    for n in names:
        mm = re.match(r"(GET|POST|PUT|PATCH|DELETE) (.*)", n)
        if not mm:
            continue
        r = match(mm.group(1), mm.group(2))
        if not r and mm.group(2).startswith("/dashboard"):
            r = {"Method": mm.group(1), "Path": mm.group(2), "Svc": "gateway", "Where": "backend/cmd/gateway/main.go", "Roles": [], "Checks": [], "SQLFuncs": [], "Writes": [], "Topics": [], "Audience": [], "Storage": False}
        out.append(r if r else n)
    return out


def routes_of(app):
    src = open(os.path.join(REPO, app, "lib/core/router/app_router.dart"), encoding="utf-8").read()
    res = {}
    for m in re.finditer(r"path:\s*'([^']+)'[^;]*?builder:\s*\([^)]*\)\s*(?:=>|\{[^}]*return)\s*(?:const\s+)?(\w+)\(", src, re.S):
        res.setdefault(m.group(2), []).append(m.group(1))
    return res


def write_mobile(app, fn, title, outfile):
    blocks = parse_outline(fn)
    rmap = routes_of(app)
    o = ["# %s" % title, "", "Kaynak: `%s/lib/`. Rotalar: `%s/lib/core/router/app_router.dart`. API istemcisi: `%s/lib/core/network/api_client.dart`." % (app, app, app), ""]
    total, screens = 0, 0
    for k in sorted(blocks):
        lines = blocks[k]
        if not any(x.split(" ", 2)[1] in ("DÜĞME", "OKUR", "SEÇİM", "EKRAN") for x in lines if len(x.split(" ", 2)) > 1):
            continue
        screens += 1
        classes = [x.split(" ", 2)[2] for x in lines if len(x.split(" ", 2)) > 2 and x.split(" ", 2)[1] == "EKRAN"]
        rts = sorted(set(r for c in classes for r in rmap.get(c, [])))
        rel = os.path.relpath(k, app + "/lib")
        o.append("### %s" % rel.split("/")[-1].replace(".dart", ""))
        o.append("- **Dosya:** `%s`" % k)
        if rts:
            o.append("- **Rota:** %s" % ", ".join("`%s`" % r for r in rts))
        view, acts = render_items(lines, mobile_calls)
        STRUCT[app].append({"title": rel.split("/")[-1].replace(".dart", ""), "file": k, "routes": rts, "view": view, "actions": list(LAST)})
        if view:
            o.append("- **Ekranda:**")
            o += ["  " + v for v in view]
        if acts:
            total += len(acts)
            o += ["", HEAD] + acts
        o.append("")
    open(os.path.join(OUT, outfile), "w").write("\n".join(o))
    return total, screens


def floc(rel, needle, short=None):
    path = os.path.join(REPO, rel)
    for i, line in enumerate(open(path), 1):
        if needle in line:
            return "`%s:%d`" % (short or rel, i)
    raise SystemExit("floc: %s içinde %r yok" % (rel, needle))


# ---------------- ORTAK ----------------
def write_common():
    o = ["# 4. Bildirimler, zamanlanmış işler, bekçiler, tetikleyiciler", ""]
    o += ["## 4.1 Bildirim kanalları ve nerede görüldükleri", "",
          "- Kanallar: `IN_APP`, `PUSH`, `SMS` (Netgsm), `EMAIL` (SMTP) — `backend/pkg/notify/notify.go`. Sağlayıcısı yapılandırılmamış kanal \"kuyrukta bekliyor\" kalır; PUSH için sağlayıcı yok.",
          "- Kategori: `TRANSACTIONAL` (onay gerekmez) / `COMMERCIAL` (6563 m.6 — önceden onay şart).",
          "- **Kişisel bildirim kutusu üç istemcide de var (073):** `GET /notifications` (okundu bilgisiyle, `notification_reads`), `GET /notifications/unread-count`, `POST /notifications/:id/read`, `POST /notifications/read-all` → Panel üst bar zili + `/dashboard/inbox`, Sakin `notifications_screen`, Yön.mobil `inbox_screen` (ana ekranda okunmamış sayısı). Sitenin bütün bildirimleri (giden kutusu, `GET /notifications/outbox`) panelde *Bildirimler* sayfasında ve Yön.mobil `notification_center` ekranındadır.",
          "- Gönderilmiş bildirim silinemez/değiştirilemez (tetikleyici `notifications_sent_final`); pasif sitede yeni bildirim yazılamaz (`notifications_active_property`).",
          "- Alıcı kümeleri (`backend/pkg/notify/audience.go`): Residents (aktif sakinler, kişi başı tek), UnitResidents (dairenin aktif sakinleri), UnitUsers (daireyi kullananlar), AssessmentPayers (tahakkukun sorumlusu), BlockNeighbors (aynı blok), Tenants (kiracılar), UnitOwners (malikler), Managers (MANAGER/BOARD_MEMBER/AUDITOR), Approvers (MANAGER/BOARD_MEMBER), Operations (MANAGER/BOARD_MEMBER/STAFF).", ""]
    o += ["## 4.2 İstek üzerine üretilen bildirimler (uç → konu → alıcı)", "", "| Uç | Servis · kayıt | Konu | Alıcı |", "|---|---|---|---|"]
    for r in cg:
        if r["Topics"] or r["Audience"]:
            o.append("| `%s %s` | %s · `%s` | %s | %s |" % (r["Method"], r["Path"], r["Svc"], r["Where"], ", ".join("`%s`" % t for t in r["Topics"] or []) or "—", ", ".join(r["Audience"] or []) or "işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta"))
    o += ["", "## 4.3 Zamanlanmış işler (`backend/cmd/scheduler`, varsayılan 15 dk'da bir, `SCHEDULER_INTERVAL`) — 14 iş", "",
          "| İş | Ne yapar | Konu | Alıcı | Kod |", "|---|---|---|---|---|",
          "| dues.overdue | Vadesi geçmiş aidat: daireye ayda en fazla bir hatırlatma; kiracı sorumluluğundaysa malike de | `dues.overdue`, `dues.overdue.tenant` | AssessmentPayers; UnitOwners | %s |" % floc('backend/cmd/scheduler/jobs.go', 'func overdueDues(', 'backend/cmd/scheduler/jobs.go'),
          "| contract.notice | İhbar son günü yaklaşan/geçen sözleşme | `contract.notice` | Managers | %s |" % floc('backend/cmd/scheduler/jobs.go', 'func contractNotices(', 'jobs.go'),
          "| contract.expired | Süresi dolduğu hâlde ACTIVE sözleşme | `contract.expired` | Managers | %s |" % floc('backend/cmd/scheduler/jobs.go', 'func expiredContracts(', 'jobs.go'),
          "| patrol.overdue | Beklenen süre + tolerans aşılmış açık devriye | `patrol.overdue` | Managers | %s |" % floc('backend/cmd/scheduler/jobs.go', 'func overduePatrols(', 'jobs.go'),
          "| asset.maintenance | Bakım/periyodik kontrol tarihi yaklaşan/geçen demirbaş | `asset.maintenance.*` | Managers | %s |" % floc('backend/cmd/scheduler/jobs.go', 'func maintenanceDue(', 'jobs.go'),
          "| kvkk.due | KVKK m.13 yanıt süresi dolmak üzere/dolmuş başvuru | `kvkk.due.*` | Managers | %s |" % floc('backend/cmd/scheduler/jobs.go', 'func kvkkDue(', 'jobs.go'),
          "| budget.approval | Geçici işletme projesinin genel kurul süresi (KMK m.37, 3 ay) | `budget.approval.*` | Managers | %s |" % floc('backend/cmd/scheduler/jobs.go', 'func budgetApprovalDue(', 'jobs.go'),
          "| emergency.drill | Yıllık tatbikat süresi geçmiş / hiç tatbikat yok | `emergency.drill` | Managers | %s |" % floc('backend/cmd/scheduler/jobs.go', 'func drillDue(', 'jobs.go'),
          "| compliance.employer | SGK işe giriş/çıkış, MUHSGK/prim son günü | `compliance.*` | Managers | %s |" % floc('backend/cmd/scheduler/jobs.go', 'func employerCompliance(', 'jobs.go'),
          "| kvkk.destruction | Saklama süresi dolan ziyaretçi/otopark/kargo kayıtlarını anonimleştirir (≤6 ayda bir); süre tanımsızsa hatırlatır | `kvkk.destruction.done`, `kvkk.destruction.undefined` | Managers | %s |" % floc('backend/cmd/scheduler/jobs.go', 'func periodicDestruction(', 'jobs.go'),
          "| dask.renewal | 30 gün içinde biten/bitmiş DASK poliçesi | `dask.*` | UnitResidents (malik) | %s |" % floc('backend/cmd/scheduler/jobs.go', 'func daskRenewal(', 'jobs.go'),
          "| activity.purge | Saklama süresi dolan uygulama içi etkinlik kayıtlarını siler (ACTIVITY_LOG_RETENTION_DAYS) | — | — | %s |" % floc('backend/cmd/scheduler/jobs.go', 'func purgeClientActivity(', 'jobs.go'),
          "| sensor.purge | 365 günden eski sensör okumalarını siler | — | — | %s |" % floc('backend/cmd/scheduler/jobs.go', 'func purgeSensorReadings(', 'jobs.go'),
          "| patrol.track.purge | 1 yıldan eski devriye konum izini siler | — | — | %s |" % floc('backend/cmd/scheduler/jobs.go', 'func purgePatrolTracks(', 'jobs.go'),
          "", "Mükerrer gönderim `DedupeKey` ile engellenir (ör. `dues.overdue:<daire>:<ay>`, %s)." % floc("backend/cmd/scheduler/jobs.go", 'DedupeKey: "dues.overdue:"', "jobs.go"), "",
          "## 4.4 Servis içi bekçiler", "",
          "| Bekçi | Aralık | Ne yapar | Kod |", "|---|---|---|---|",
          "| Kart ödemesi uzlaştırma | 1 dk (`CARD_RECONCILE_INTERVAL`), 20 dk'dan eski askıdaki ödemeler (`CARD_RECONCILE_AGE`) | Sonucu iyzico'dan yeniden sorgular, askıda ödeme bırakmaz | %s |" % floc("backend/services/finance/card.go", "func startCardReconcile("),
          "| Geçiş cihazı canlılığı | 30 sn (`DEVICE_WATCH_INTERVAL`) | Sinyal kesilen cihaz için olay açar; `device.offline`/`device.recovered` bildirimi → Operations | %s |" % floc("backend/services/parking/devices.go", "func startDeviceWatch("),
          "| Sensör sinyal bekçisi | 60 sn (`SENSOR_WATCH_INTERVAL`) | Sinyali kesilen sensör için OFFLINE alarmı açar; `iot.offline` → Operations (074) | %s |" % floc("backend/services/iot/sensors.go", "func startSensorWatch("),
          "| Kargo teslim kanıtı imhası | 15 dk (`PACKAGE_PURGE_INTERVAL`) | Silme kuyruğundaki kanıt dosyalarını depodan siler | %s |" % floc("backend/services/package/proof.go", "func startDeletionWorker("), ""]
    o += ["## 4.5 Veritabanı tetikleyicileri (son tanım geçerli)", "", "| Tablo | Tetikleyici | Ne zaman | Etki / engel | Migration |", "|---|---|---|---|---|"]
    for t in trig:
        eff = ", ".join(t["writes"]) if t["writes"] else ""
        if t["raises"]:
            eff = (eff + " · " if eff else "") + "engeller: " + esc(t["raises"][0])
        o.append("| %s | %s | %s | %s | %s |" % (t["table"], t["name"], t["when"], eff or "satırı düzenler (NEW)", t["func_mig"] or t["mig"]))
    o += ["", "## 4.6 Denetim izi", "",
          "Her serviste API grubu `middleware.AuditLog` ile sarılı (`backend/pkg/middleware/auth.go:162`): GET dahil her istek `audit_logs`'a `VIEW/CREATE/UPDATE/DELETE` olarak, 403'ler `DENIED` olarak yazılır; 401'ler yazılmaz. Ek olarak: `document_access_logs` (belge erişimi, salt-ekleme), personel kişisel verisinin maskesiz görüntülenmesi `PII_REVEAL`. Panelde denetim izini listeleyen bir sayfa yoktur.", ""]
    open(os.path.join(OUT, "04-bildirim-zamanlayici-tetikleyici.md"), "w").write("\n".join(o))


def write_unused():
    o = ["# 5. Arayüzsüz uçlar ve tutarsızlıklar", "", "## 5.1 Backend'de olup hiçbir istemcide (panel, sakin, yönetici mobil) çağrılmayan uçlar", "",
         "| Uç | Servis · kayıt | Yetki | Değişen tablolar | Bildirim |", "|---|---|---|---|---|"]
    manual_used = {"GET /public/clearance/:code": "Panel /dogrula/[code] (fetch)", "POST /auth/refresh": "istemcilerin jeton yenilemesi", "POST /public/payments/iyzico/callback": "iyzico tarayıcı dönüşü", "POST /public/devices/heartbeat": "geçiş cihazı (X-Device-Key)", "POST /public/sensors/data": "IoT sensörü (X-Device-Key, 074)"}
    for r in cg:
        k = "%s %s" % (r["Method"], r["Path"])
        if k in cons or r["Svc"] in ("banking", "meeting_wizard"):
            continue
        note = manual_used.get(k)
        o.append("| `%s`%s | %s · `%s` | %s | %s | %s |" % (k, " — " + note if note else "", r["Svc"], r["Where"], roles_of(r), writes_of(r), notif_of(r)))
    o += ["", "## 5.2 Yazılmamış modüller (501)", ""]
    for s in ("banking", "meeting_wizard"):
        rs = SVC_OF.get(s, [])
        if not rs:
            continue
        o.append("- **%s** — %d uç, hepsi 501: %s" % (s, len(rs), ", ".join("`%s %s`" % (r["Method"], r["Path"]) for r in rs)))
    o += ["", "Bulunan tutarsızlıklar ve eksikler: [6. Bulgular ve eksikler](06-bulgular-ve-eksikler.md).", ""]
    open(os.path.join(OUT, "05-arayuzsuz-uclar.md"), "w").write("\n".join(o))


os.makedirs(OUT, exist_ok=True)
pa, pp = write_panel()
ma, ms = write_mobile("mobile", "mobile_outline.txt", "2. Sakin mobil uygulaması — ekran ekran", "02-sakin-mobil.md")
aa, as_ = write_mobile("admin_app", "adminapp_outline.txt", "3. Yönetici mobil uygulaması — ekran ekran", "03-yonetici-mobil.md")
write_common()
write_unused()
json.dump({"pages": STRUCT, "routes": [route_info(r) for r in cg], "rules": rules, "consumers": cons},
          open(os.path.join(S, "harita.json"), "w"), ensure_ascii=False, indent=0)
print(json.dumps({"panel_sayfa": pp, "panel_eylem": pa, "sakin_ekran": ms, "sakin_eylem": ma, "yon_ekran": as_, "yon_eylem": aa}))
