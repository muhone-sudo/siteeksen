#!/usr/bin/env python3
import re, sys, json

src = re.sub(r"\},[ \t]+(\w+):\s*\{", r"},\n        \1: {", open(sys.argv[1], encoding="utf-8").read()).split("\n")
routes = json.load(open(sys.argv[2]))
CALL = re.compile(r"\b(g|http\.(get|post|put|patch|del|upload|download))(?:<[^(]*>)?\(\s*([\"`])((?:[^\"`$?]|\$\{[^}]*\})+)")
TERN = re.compile(r"\$\{[^}?]*\?\s*[\"']([^\"']*)[\"']\s*:\s*[\"']([^\"']*)[\"']\s*\}")


def variants(path):
    m = TERN.search(path)
    if not m:
        return [path]
    return [v for alt in (m.group(1), m.group(2)) for v in variants(path[:m.start()] + alt + path[m.end():])]
KEY = re.compile(r"^\s+(\w+):\s*(?:\(|async|\w+\s*=>)")
GROUP = re.compile(r"^\s+(\w+):\s*\{\s*$")

stack, out, pending = [], {}, None
for i, l in enumerate(src):
    g = GROUP.match(l)
    if g:
        stack.append(g.group(1)); continue
    if re.match(r"^\s+\},?\s*$", l) and stack:
        stack.pop(); continue
    k = KEY.match(l)
    if k and stack:
        pending = (".".join(stack) + "." + k.group(1), i + 1)
    for m in CALL.finditer(l):
        if pending:
            verb = {"g": "GET", "http.get": "GET", "http.post": "POST", "http.put": "PUT", "http.patch": "PATCH",
                    "http.del": "DELETE", "http.upload": "POST", "http.download": "GET"}[m.group(1)]
            for raw in variants(m.group(4)):
                path = re.sub(r"\$\{[^}]+\}", ":p", raw).split("?")[0]
                out.setdefault(pending[0], []).append({"verb": verb, "path": path, "line": pending[1],
                                                       "dl": m.group(1) == "http.download"})


def match(verb, path):
    segs = path.strip("/").split("/")
    for strict in (True, False):
        best, score = None, -1
        for r in routes:
            if r["method"] not in (verb, "Any"):
                continue
            rs = r["path"].strip("/").split("/")
            if len(rs) != len(segs):
                continue
            if all(a == b or a.startswith(":") or a.startswith("*") or (not strict and ":p" in b) for a, b in zip(rs, segs)):
                sc = sum(a == b for a, b in zip(rs, segs))
                if sc > score:
                    best, score = r, sc
        if best:
            return best
    return None


res, miss = {}, []
for name, calls in out.items():
    for c in calls:
        r = match(c["verb"], c["path"])
        c["backend"] = r and {k: r[k] for k in ("svc", "path", "roles", "where", "handler", "incheck", "notify", "sql", "store")}
        if not r and not c["path"].startswith("/dashboard") or (not r):
            miss.append("%s %s %s" % (name, c["verb"], c["path"]))
    res[name] = calls
json.dump(res, open(sys.argv[3], "w"), ensure_ascii=False, indent=0)
print(len(res), "panel yöntemi;", len(miss), "eşleşmeyen")
print("\n".join(miss))
