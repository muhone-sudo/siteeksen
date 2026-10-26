#!/usr/bin/env python3
import os, re, sys, json

ROOT = sys.argv[1]
SERVICES = os.path.join(ROOT, "services")
GROUP = re.compile(r"(\w+)\s*:=\s*(\w+)\.Group\(\"([^\"]*)\"(.*)")
USE = re.compile(r"^\s*(\w+)\.Use\(")
ROUTE = re.compile(r"\b(\w+)\.(GET|POST|PUT|PATCH|DELETE|Any)\(\"([^\"]*)\"\s*,\s*(.*)")
ROLEVAR = re.compile(r"(\w+)\s*:?=\s*middleware\.RequireRole\(")
ROLE = re.compile(r"Role([A-Z][a-zA-Z]+)")
INCHECK = re.compile(r"\b(isManagement|isFinanceManager|hasRole|hasAnyRole|isManager|isManagementRole|canManage|residentScope|reportRoles|resident_can_use|assessment_visible_to|getRoles)\b")
NOTIFY = re.compile(r"\b(notify[A-Z]\w*|NotifyCharges|Broadcast|Enqueue|sendActivation\w*|sendInvitation\w*|sendSelfResetCode|notifyContacts|notifyOldPhone)\(")
AUDIT = re.compile(r"\b(audit\.\w+|AuditLog|PII_REVEAL|document_access_logs)\b")
STORE = re.compile(r"\b(storage\.\w+|\.Put\(|FormFile)\b")
SQLR = re.compile(r"\b(?:FROM|JOIN)\s+([a-z_]{3,})\b")
SQLW = re.compile(r"\b(INSERT INTO|UPDATE|DELETE FROM)\s+([a-z_]+)", re.I)


def read(p):
    return open(p, encoding="utf-8").read().split("\n")


SLICES = {}


def roles_in(text):
    rs = set(ROLE.findall(text))
    for v in re.findall(r"RequireRole\((\w+)\.\.\.\)", text):
        rs |= set(SLICES.get(v, []))
    return sorted(rs)


def balanced_end(lines, i):
    depth, started = 0, False
    for j in range(i, len(lines)):
        for ch in lines[j]:
            if ch in "({":
                depth += 1; started = True
            elif ch in ")}":
                depth -= 1
        if started and depth <= 0:
            return j
    return len(lines) - 1


def func_index(svcdir):
    idx = {}
    for dp, _, fns in os.walk(svcdir):
        for fn in fns:
            if not fn.endswith(".go") or fn.endswith("_test.go"):
                continue
            p = os.path.join(dp, fn)
            L = read(p)
            for i, l in enumerate(L):
                cm = re.match(r"^(?:const|var)\s+(\w+)\s*=\s*`", l) or re.match(r"^\t(\w+)\s*=\s*`", l)
                if cm:
                    end = i
                    while end + 1 < len(L) and (end == i or "`" not in L[end]):
                        end += 1
                    idx.setdefault(cm.group(1), []).append((p, i, L[i:end + 1]))
                    continue
                m = re.match(r"^func (?:\([^)]*\) )?(\w+)\(", l)
                if m:
                    end = i
                    while end + 1 < len(L) and L[end] != "}" and not (end > i and L[end].startswith("}")):
                        end += 1
                    idx.setdefault(m.group(1), []).append((p, i, L[i:end + 1]))
    return idx


def body_facts(body, idx, depth=0, seen=None, caller=""):
    seen = seen or set()
    text = "\n".join(body)
    f = {"incheck": set(INCHECK.findall(text)), "notify": set(NOTIFY.findall(text)),
         "audit": set(AUDIT.findall(text)), "store": bool(STORE.search(text)),
         "sql": set((a.upper(), b) for a, b in SQLW.findall(text)), "reads": set(SQLR.findall(text)) - {"jsonb_array_elements","unnest","generate_series","lateral"}}
    if depth < 5:
        for call in set(re.findall(r"\b([a-zA-Z]\w*)\(", text)) | set(w for w in re.findall(r"\b([a-zA-Z]\w*)\b", text) if w in idx and idx[w][0][2] and "`" in idx[w][0][2][0]):
            if call not in idx:
                continue
            dirs = [os.path.dirname(fp) for fp, _, _ in idx[call]]
            for fp, ln, b in idx[call]:
                if dirs.count(os.path.dirname(fp)) > 1 and os.path.basename(fp) != os.path.basename(caller):
                    continue
                if (fp, ln) in seen:
                    continue
                seen.add((fp, ln))
                sub = body_facts(b, idx, depth + 1, seen, fp)
                for k in ("incheck", "notify", "audit", "sql", "reads"):
                    f[k] |= sub[k]
                f["store"] |= sub["store"]
    return f


def service_routes(name):
    d = os.path.join(SERVICES, name)
    idx = func_index(d)
    out = []
    for fn in sorted(os.listdir(d)):
        if not fn.endswith(".go") or fn.endswith("_test.go"):
            continue
        p = os.path.join(d, fn)
        L = read(p)
        src = "\n".join(L)
        if "\npackage main" not in "\n" + src:
            continue
        prefix, groles, rvars = {"r": ""}, {"r": []}, {}
        SLICES.clear()
        for sm in re.finditer(r"(\w+)\s*:?=\s*\[\]string\{([^}]*)\}", src):
            if "Role" in sm.group(2):
                SLICES[sm.group(1)] = ROLE.findall(sm.group(2))
        for i, l in enumerate(L):
            m = ROLEVAR.search(l)
            if m:
                e = balanced_end(L, i)
                rvars[m.group(1)] = roles_in("\n".join(L[i:e + 1]))
            m = GROUP.search(l)
            if m:
                var, parent, path, rest = m.groups()
                prefix[var] = prefix.get(parent, "") + path
                e = balanced_end(L, i)
                gtxt = "\n".join(L[i:e + 1])
                rs = roles_in(gtxt) if "RequireRole" in gtxt else []
                for v, vr in rvars.items():
                    if re.search(r"\b%s\b" % v, rest):
                        rs = vr
                groles[var] = rs or list(groles.get(parent, []))
            m = USE.match(l)
            if m and m.group(1) in groles:
                e = balanced_end(L, i)
                t = "\n".join(L[i:e + 1])
                if "RequireRole" in t:
                    groles[m.group(1)] = roles_in(t)
            m = ROUTE.search(l)
            if m:
                var, method, path, rest = m.groups()
                full = prefix.get(var, "") + path
                if not full.startswith("/api/v1/"):
                    continue
                e = balanced_end(L, l.index(m.group(0)) and i)
                stmt = "\n".join(L[i:e + 1])
                rs = roles_in(stmt.split("func(")[0]) if "RequireRole" in stmt.split("func(")[0] else []
                for v, vr in rvars.items():
                    if re.search(r"\b%s\b" % v, rest):
                        rs = vr
                rs = rs or groles.get(var, [])
                if "func(c *gin.Context)" in rest:
                    body, hname = L[i:e + 1], "(satır içi)"
                else:
                    calls = re.findall(r"(?:\w+\.)?(\w+)\(", rest)
                    hname = calls[-1] if calls else rest.strip()
                    calls = [c for c in calls if c not in ("RequireRole", "AuditLog")]
                    hname = calls[0] if calls else hname
                    body = []
                    hfile = p
                    for hp, _, b in idx.get(hname, [])[:1]:
                        body, hfile = b, hp
                facts = body_facts(body, idx, caller=hfile if "func(c *gin.Context)" not in rest else p)
                if "AuditLog" in stmt:
                    facts["audit"].add("AuditLog")
                out.append({"svc": name, "method": method, "path": full[7:], "roles": rs,
                            "where": "%s:%d" % (os.path.relpath(p, ROOT), i + 1), "handler": hname,
                            "incheck": sorted(facts["incheck"]), "notify": sorted(facts["notify"]),
                            "audit": sorted(facts["audit"]), "store": facts["store"],
                            "sql": sorted("%s %s" % x for x in facts["sql"]), "reads": sorted(facts["reads"])})
    return out


allr = []
for s in sorted(os.listdir(SERVICES)):
    if os.path.isdir(os.path.join(SERVICES, s)):
        allr += service_routes(s)
json.dump(allr, open(sys.argv[2], "w"), ensure_ascii=False, indent=0)
print(len(allr), "rota")
