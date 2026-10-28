#!/usr/bin/env python3
import os, re, sys, json

REPO, S = sys.argv[1], sys.argv[2]
routes = json.load(open(os.path.join(S, "cg.json")))
panel = json.load(open(os.path.join(S, "panel_ep.json")))


TERN = re.compile(r"\$\{[^}?]*\?\s*[\"']([^\"']*)[\"']\s*:\s*[\"']([^\"']*)[\"']\s*\}")


def variants(path):
    m = TERN.search(path)
    if not m:
        return [path]
    return [v for alt in (m.group(1), m.group(2)) for v in variants(path[:m.start()] + alt + path[m.end():])]


def match_one(verb, path):
    path = re.sub(r"\$\{[^}]+\}|\$\w+", ":p", path).split("?")[0]
    segs = [x for x in path.strip("/").split("/") if x]
    for strict in (True, False):
        best, score = None, -1
        for r in routes:
            if r["Method"] not in (verb, "Any"):
                continue
            rs = r["Path"].strip("/").split("/")
            if len(rs) != len(segs):
                continue
            if all(a == b or a.startswith(":") or a.startswith("*") or (not strict and ":p" in b) for a, b in zip(rs, segs)):
                sc = sum(a == b for a, b in zip(rs, segs))
                if sc > score:
                    best, score = r["Method"] + " " + r["Path"], sc
        if best:
            return best
    return None


def match(verb, path):
    return [m for m in (match_one(verb, v) for v in variants(path)) if m]


uses = {}


def add(route, who):
    for r in route or []:
        uses.setdefault(r, set()).add(who)


# --- panel: sayfa -> api yöntemleri (bileşenler dahil) ---
ADM = os.path.join(REPO, "admin", "src")
API = re.compile(r"\bapi\.(\w+\.\w+)\b")
comp_api = {}
for dp, _, fns in os.walk(os.path.join(ADM, "components")):
    for fn in fns:
        if fn.endswith(".tsx"):
            p = os.path.join(dp, fn)
            comp_api[os.path.splitext(fn)[0]] = (os.path.relpath(p, REPO), set(API.findall(open(p).read())))
page_api = {}
for dp, _, fns in os.walk(os.path.join(ADM, "app")):
    for fn in fns:
        if fn == "page.tsx":
            p = os.path.join(dp, fn)
            src = open(p).read()
            name = "/" + os.path.relpath(dp, os.path.join(ADM, "app")).replace("(dashboard)/", "").replace("(dashboard)", "")
            name = name.rstrip("/.") or "/"
            calls = set(API.findall(src))
            for imp in re.findall(r"from\s+\"@/components/[\w/-]*/([\w-]+)\"", src):
                if imp in comp_api:
                    calls |= comp_api[imp][1]
            page_api[name] = sorted(calls)
for c, (path, calls) in comp_api.items():
    if c in ("sidebar", "header"):
        page_api["(kenar çubuğu/üst bar: %s)" % c] = sorted(calls)
for page, calls in page_api.items():
    for m in calls:
        for c in panel.get(m, []):
            add(c["backend"] and match(c["verb"], c["path"]), "Panel " + page)

# --- mobil ---
VERB = {"get": "GET", "getList": "GET", "getMap": "GET", "post": "POST", "postMultipart": "POST", "put": "PUT",
        "patch": "PATCH", "delete": "DELETE", "downloadBytes": "GET", "openDownload": "GET", "optionsFrom": "GET", "_open": "GET"}
DIO = re.compile(r"\.(get|post|put|patch|delete)(?:<[^(]*?>)?\(\s*(['\"])(/(?:[^'\"$]|\$\{[^}]*\}|\$\w)+)\2")
GEN = re.compile(r"(?<![\w])(?:\w+\.)?(getList|getMap|post|put|patch|delete|postMultipart|downloadBytes|openDownload|optionsFrom|_open)\(\s*(?:context,\s*)?(['\"])(/(?:[^'\"$]|\$\{[^}]*\}|\$\w)+)\2")
METH = re.compile(r"^\s*Future<.*?>\s+(\w+)\(", re.M)
mobile_named = {}
for app in ("mobile", "admin_app"):
    cli = os.path.join(REPO, app, "lib", "core", "network", "api_client.dart")
    src = open(cli).read()
    pos = [(m.start(), m.group(1)) for m in METH.finditer(src)] + [(len(src), None)]
    named = {}
    for (a, n), (b, _) in zip(pos, pos[1:]):
        body = src[a:b]
        hits = [(VERB[v], p) for v, _, p in DIO.findall(body)] + [(VERB[v], p) for v, _, p in GEN.findall(body)]
        if hits:
            named[n] = hits
    mobile_named[app] = named
    for dp, _, fns in os.walk(os.path.join(REPO, app, "lib")):
        for fn in fns:
            if not fn.endswith(".dart") or "core/network" in dp:
                continue
            p = os.path.join(dp, fn)
            src = open(p).read()
            label = ("Sakin " if app == "mobile" else "Yönetici-mobil ") + fn.replace(".dart", "")
            for v, _, path in GEN.findall(src) + DIO.findall(src):
                add(match(VERB[v], path), label)
            for n, hits in named.items():
                if re.search(r"\.%s\(" % n, src):
                    for v, path in hits:
                        add(match(v, path), label)

json.dump({k: sorted(v) for k, v in uses.items()}, open(os.path.join(S, "consumers.json"), "w"), ensure_ascii=False, indent=0)
json.dump(page_api, open(os.path.join(S, "page_api.json"), "w"), ensure_ascii=False, indent=0)
json.dump(mobile_named, open(os.path.join(S, "mobile_named.json"), "w"), ensure_ascii=False, indent=0)
used = set(uses)
allr = set(r["Method"] + " " + r["Path"] for r in routes)
print(len(used), "rota en az bir istemcide kullanılıyor;", len(allr - used), "rota hiçbir istemcide yok")
