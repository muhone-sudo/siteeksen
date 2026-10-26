#!/usr/bin/env python3
import os, re, sys, json

D = sys.argv[1]
funcs, trigs = {}, {}
FN = re.compile(r"CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+(?:public\.)?(\w+)\s*\((.*?)\$(\w*)\$(.*?)\$\3\$", re.S | re.I)
TR = re.compile(r"CREATE\s+(?:OR\s+REPLACE\s+)?(?:CONSTRAINT\s+)?TRIGGER\s+(\w+)\s+(.*?)\s+ON\s+(?:public\.)?(\w+)(.*?)EXECUTE\s+(?:FUNCTION|PROCEDURE)\s+(?:public\.)?(\w+)", re.S | re.I)
DROP = re.compile(r"DROP\s+TRIGGER\s+(?:IF\s+EXISTS\s+)?(\w+)\s+ON\s+(?:public\.)?(\w+)", re.I)
W = re.compile(r"\b(INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+(?:public\.)?([a-z_]+)", re.I)
RAISE = re.compile(r"RAISE\s+EXCEPTION\s+'([^']{0,140})", re.I)
for fn in sorted(os.listdir(D)):
    if not fn.endswith(".sql"):
        continue
    s = open(os.path.join(D, fn), encoding="utf-8").read()
    s = re.sub(r"--[^\n]*", "", s)
    events = []
    for m in FN.finditer(s):
        events.append((m.start(), "fn", m))
    for m in TR.finditer(s):
        events.append((m.start(), "tr", m))
    for m in DROP.finditer(s):
        events.append((m.start(), "drop", m))
    for _, kind, m in sorted(events, key=lambda e: e[0]):
        if kind == "fn":
            body = m.group(4)
            funcs[m.group(1)] = {"mig": fn, "writes": sorted(set("%s %s" % (a.split()[0].upper(), b) for a, b in W.findall(body))),
                                 "raises": [r.strip() for r in RAISE.findall(body)][:4]}
        elif kind == "tr":
            trigs[(m.group(1), m.group(3))] = {"name": m.group(1), "table": m.group(3), "when": " ".join(m.group(2).split()),
                                               "func": m.group(5), "mig": fn}
        else:
            trigs.pop((m.group(1), m.group(2)), None)
out = []
for t in trigs.values():
    f = funcs.get(t["func"], {})
    t["writes"] = f.get("writes", [])
    t["raises"] = f.get("raises", [])
    t["func_mig"] = f.get("mig", "")
    out.append(t)
out.sort(key=lambda t: (t["table"], t["name"]))
json.dump(out, open(sys.argv[2], "w"), ensure_ascii=False, indent=0)
print(len(out), "tetikleyici,", len(set(t["table"] for t in out)), "tablo")
