#!/usr/bin/env python3
import re, sys, json

named = json.load(open(sys.argv[1]))
app = sys.argv[2]
NAMED = named[app]
GEN = re.compile(r"(?<![\w])(?:\w+\.)?(getList|getMap|post|put|patch|delete|postMultipart|downloadBytes)\(\s*(['\"])(/(?:[^'\"$]|\$\{[^}]*\}|\$\w)+)\2")
VERB = {"getList": "GET", "getMap": "GET", "post": "POST", "put": "PUT", "patch": "PATCH", "delete": "DELETE", "postMultipart": "POST", "downloadBytes": "GET"}
WIDGETS = r"(ElevatedButton|FilledButton|TextButton|OutlinedButton|IconButton|FloatingActionButton|ListTile|SwitchListTile|CheckboxListTile|InkWell|GestureDetector|PopupMenuItem|ActionChip|ChoiceChip|FilterChip|SegmentedButton|DropdownButtonFormField|DropdownButton)(?:\.\w+)?\("


def close(src, i):
    depth, q, j = 0, None, i
    while j < len(src):
        ch = src[j]
        if q:
            if ch == q and src[j - 1] != "\\":
                q = None
        elif ch in "'\"":
            q = ch
        elif ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
            if depth == 0:
                return j
        j += 1
    return len(src) - 1


def ln(src, i):
    return src.count("\n", 0, i) + 1


def strs(s):
    return re.findall(r"Text\(\s*(?:'([^']*)'|\"([^\"]*)\")", s)


def first_text(s):
    for a, b in strs(s):
        if (a or b).strip():
            return (a or b)[:70]
    i = s.find("Text(")
    if i >= 0:
        seg = s[i:close(s, i + 4) + 1]
        q = [x for x in re.findall(r"'([^']*)'", seg) if x.strip()]
        if q:
            return " / ".join(q)[:90]
    m = re.search(r"(?:tooltip|label|labelText|title|semanticLabel):\s*'([^']+)'", s)
    return m.group(1)[:70] if m else None


def api_calls(s):
    out = []
    for p in re.findall(r"\b(?:_open\w*|_download\w*|_export\w*|_share\w*|openReport|download\w*)\(\s*(?:context\s*,\s*)?'(/[^']+)'", s):
        out.append("GET %s" % p)
    for v, _, p in GEN.findall(s):
        out.append("%s %s" % (VERB[v], p))
    for n, hits in NAMED.items():
        if re.search(r"\.%s\(" % n, s):
            out += ["%s %s" % tuple(h) for h in hits]
    return list(dict.fromkeys(out))


def handler(s):
    m = re.search(r"\b(onPressed|onTap|onChanged|onSelected|onSelectionChanged)\s*:\s*", s)
    if not m:
        return None, ""
    rest = s[m.end():]
    if rest.startswith("null"):
        return m.group(1), "pasif"
    tern0 = re.match(r"(?:\([^()]*\)|[^,?(])*?\?\s*null\s*:\s*", rest)
    if tern0 and tern0.end() < 200:
        r2 = rest[tern0.end():]
        if r2[:1] == "(":
            e = close(r2, 0)
            k = e + 1
            while k < len(r2) and r2[k] in " =>\n":
                k += 1
            tail = r2[k:close(r2, k) + 1] if k < len(r2) and r2[k] in "({" else r2[k:k + 200].split(",")[0]
            return m.group(1), r2[:e + 1] + tail
        nm2 = re.match(r"[\w.]+", r2)
        return m.group(1), nm2.group(0) if nm2 else ""
    tern = re.match(r"(?:\([^()]*\)|[^,?(])+?\?\s*(\(?[^:]*?\)?)\s*:\s*null", rest, re.S)
    if tern:
        inner = tern.group(1).strip()
        if inner.startswith("("):
            k = rest.find(inner)
            return m.group(1), rest[k:close(rest, k) + 1] + rest[close(rest, k) + 1:close(rest, k) + 400]
        return m.group(1), inner
    if rest[:1] in "({" or rest.startswith("()") or rest.startswith("(_)") or rest.startswith("("):
        e = close(rest, 0)
        body = rest[:e + 1]
        e2 = rest.find(",", e)
        after = rest[e + 1:e + 12].lstrip()
        if after.startswith("async"):
            after = after[5:].lstrip()
        if after.startswith("=>") or after.startswith("{"):
            k = e + 1
            while k < len(rest) and (rest[k] in " =>\n\t" or rest.startswith("async", k)):
                k += 5 if rest.startswith("async", k) else 1
            if k < len(rest) and rest[k] in "({":
                body += rest[k:close(rest, k) + 1]
            else:
                nm3 = re.match(r"[\w.!]+(?:<[^>(]*>)?\(", rest[k:])
                if nm3:
                    end = close(rest, k + nm3.end() - 1)
                    while True:
                        nxt = re.match(r"\s*\.[\w!]+(?:<[^>(]*>)?\(", rest[end + 1:])
                        if not nxt:
                            break
                        end = close(rest, end + nxt.end())
                    body += rest[k:end + 1]
                else:
                    body += rest[k:rest.find(",", k) if rest.find(",", k) > 0 else k + 120]
        return m.group(1), body
    nm = re.match(r"[\w.]+", rest)
    return m.group(1), nm.group(0) if nm else ""


GLOBAL = {}
import os as _os
for _dp, _, _fns in _os.walk(_os.path.join(app, "lib")):
    for _fn in _fns:
        if _fn.endswith(".dart") and _fn != "api_client.dart":
            _src = open(_os.path.join(_dp, _fn), encoding="utf-8").read()
            for _m in re.finditer(r"^(?:Future<[^\n]*?>|void|Future|[A-Z]\w*(?:<[^\n]*?>)?)\s+([a-z]\w*)\s*\([^)]*\)\s*(?:async\s*)?\{", _src, re.M):
                GLOBAL[_m.group(1)] = _src[_m.end() - 1:close(_src, _m.end() - 1) + 1]


def follow(src, body, depth=0):
    extra = ""
    if depth > 2:
        return body
    for fn in set(re.findall(r"(?<![\w.])([a-z]\w*)\s*\(", body)):
        if fn in GLOBAL:
            extra += follow(src, GLOBAL[fn], depth + 1)
    names = set(re.findall(r"(?<![\w.])(_?[a-z]\w*|_\w+)\s*\(", body)) | set(re.findall(r"^\s*(_\w+)\s*$", body)) | set(re.findall(r"[(,:]\s*(_\w+)\s*[,)]", body))
    for fn in names:
        m = re.search(r"(?:Future<[^\n]*?>|void|Future)\s+%s\s*\(([^)]*)\)\s*(?:async\s*)?\{" % re.escape(fn), src)
        if m:
            b = src[m.end() - 1:close(src, m.end() - 1) + 1]
            params = [x.strip().split()[-1] for x in m.group(1).replace("{", "").replace("}", "").split(",") if x.strip()]
            lits = re.findall(r"(?<![\w.])%s\(\s*'([^']*)'" % re.escape(fn), body)
            if params and lits:
                for lit in set(lits):
                    extra += follow(src, re.sub(r"\$%s\b|\$\{%s\}" % (re.escape(params[0]), re.escape(params[0])), lit, b), depth + 1)
            else:
                extra += follow(src, b, depth + 1)
    m = re.match(r"^(_\w+)$", body.strip())
    return body + extra


def outline(path):
    src = open(path, encoding="utf-8").read()
    ev = []
    for m in re.finditer(r"class\s+(\w+)\s+extends\s+(StatefulWidget|StatelessWidget|ConsumerWidget|ConsumerStatefulWidget)", src):
        ev.append((m.start(), "EKRAN", m.group(1), []))
    for m in re.finditer(r"AppBar\(", src):
        a = src[m.start():close(src, m.end() - 1) + 1]
        t = re.search(r"title:\s*(?:const\s+)?Text\(\s*'([^']*)'", a)
        ev.append((m.start(), "BAŞLIK", t.group(1) if t else "(dinamik)", []))
    for m in re.finditer(r"\bTab\(\s*(?:icon:[^,]*,\s*)?text:\s*'([^']+)'", src):
        ev.append((m.start(), "SEKME", m.group(1), []))
    for m in re.finditer(r"(?:labelText|hintText):\s*'([^']+)'", src):
        ev.append((m.start(), "ALAN", m.group(1), []))
    for m in re.finditer(r"(AlertDialog|showModalBottomSheet|showDatePicker|showDialog|FilePicker|ImagePicker|image_picker|file_picker)", src):
        if m.group(1) == "AlertDialog":
            a = src[m.start():close(src, m.end()) + 1]
            ev.append((m.start(), "DİYALOG", first_text(a) or "", []))
        elif m.group(1) in ("FilePicker", "ImagePicker", "image_picker", "file_picker"):
            ev.append((m.start(), "DOSYA", m.group(1), []))
    for m in re.finditer(r"SnackBar\(\s*content:\s*(?:const\s+)?Text\(\s*'([^']+)'", src):
        ev.append((m.start(), "MESAJ", m.group(1)[:80], []))
    for m in re.finditer(r"(?:showSuccess|showError|showMessage|_snack|_toast|snack)\(\s*(?:context,\s*)?'([^']+)'", src):
        ev.append((m.start(), "MESAJ", m.group(1)[:80], []))
    starts = []
    for h in re.finditer(r"\bon(?:Pressed|Tap|LongPress):", src):
        depth, j = 0, h.start()
        while j > 0:
            j -= 1
            ch = src[j]
            if ch in ")]}":
                depth += 1
            elif ch in "([{":
                if depth == 0:
                    break
                depth -= 1
        if src[j] != "(":
            continue
        k = j
        while k > 0 and (src[k - 1].isalnum() or src[k - 1] in "_."):
            k -= 1
        starts.append(k)
    class _M:
        def __init__(self, st, en, name):
            self._s, self._e, self._n = st, en, name
        def start(self): return self._s
        def end(self): return self._e
        def group(self, i): return self._n
    found = []
    for k in sorted(set(starts)):
        j = src.find("(", k)
        found.append(_M(k, j + 1, src[k:j].split(".")[0]))
    for m in list(re.finditer(r"(DropdownButtonFormField|DropdownButton)(?:<[^>]*>)?\(", src)) + found:
        a = src[m.start():close(src, m.end() - 1) + 1]
        kind, body = handler(a)
        label = first_text(a) or "?"
        if kind is None and m.group(1) not in ("DropdownButtonFormField", "DropdownButton"):
            continue
        full = follow(src, body) if body and body != "pasif" else body
        calls = api_calls(full)
        routes = re.findall(r"context\.(?:push|go|pushNamed|goNamed)\(\s*'([^']+)'", full) + re.findall(r"context\.(?:push|go)\(\s*\"([^\"]+)\"", full)
        nav = re.findall(r"MaterialPageRoute\(\s*builder:\s*\([^)]*\)\s*=>\s*(?:const\s+)?(\w+)\(", full)
        extra = []
        if routes or nav:
            extra.append("gider: " + ", ".join(routes + nav))
        if "showDialog" in full or "showModalBottomSheet" in full:
            extra.append("pencere açar")
        if "launchUrl" in full or "url_launcher" in full or "tel:" in full:
            extra.append("dış bağlantı/arama")
        if body == "pasif":
            extra.append("pasif (onPressed: null)")
        writes = [c for c in calls if not c.startswith("GET ")]
        calls = writes or calls
        ev.append((m.start(), "DÜĞME" if m.group(1) not in ("DropdownButtonFormField", "DropdownButton") else "SEÇİM", label + (" (" + "; ".join(extra) + ")" if extra else ""), calls))
    for m in re.finditer(r"(?:initState|_load\w*|load:|future:|Future<void>\s+_refresh)\b", src):
        pass
    loads = []
    gets = [c for c in api_calls(src) if c.startswith("GET ")]
    if gets:
        loads.append((0, gets))
    for pos, calls in loads:
        ev.append((pos, "OKUR", "", calls))
    ev.sort(key=lambda x: x[0])
    seen, out = set(), []
    for pos, kind, desc, calls in ev:
        k = (kind, desc, tuple(calls))
        if kind in ("ALAN", "OKUR") and k in seen:
            continue
        seen.add(k)
        out.append("%d %s %s%s" % (ln(src, pos), kind, desc, (" ⇒ " + ", ".join(calls)) if calls else ""))
    return out


for p in sys.argv[3:]:
    print("##", p)
    print("\n".join(outline(p)))
