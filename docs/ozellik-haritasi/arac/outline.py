#!/usr/bin/env python3
import re, sys, json

API = re.compile(r"\bapi\.(\w+\.\w+)")


def line_of(src, i):
    return src.count("\n", 0, i) + 1


def tag_end(src, i):
    depth, q = 0, None
    j = i
    while j < len(src):
        ch = src[j]
        if q:
            if ch == q and src[j - 1] != "\\":
                q = None
        elif ch in "\"'`":
            q = ch
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        elif ch == ">" and depth == 0:
            return j
        j += 1
    return len(src) - 1


def attr(a, name):
    m = re.search(r"\b%s=\"([^\"]*)\"" % name, a) or re.search(r"\b%s=\{\s*\"([^\"]*)\"\s*\}" % name, a) or re.search(r"\b%s=\{`([^`]*)`\}" % name, a)
    return m.group(1) if m else None


def text(inner):
    t = re.sub(r"\{\s*/\*.*?\*/\s*\}", "", inner, flags=re.S)
    t = re.sub(r"<[^>]*>", " ", t)
    t = re.sub(r"\{([^{}]*)\}", lambda m: (m.group(1).split("?")[-1].split(":")[0].strip().strip('"') if "?" in m.group(1) and '"' in m.group(1) else ("{" + m.group(1).strip()[:30] + "}")), t)
    return " ".join(t.split())[:90]


def calls(s):
    out = []
    for m in API.finditer(s):
        if m.group(1) not in out:
            out.append(m.group(1))
    return out


def succ(s):
    m = re.findall(r"success:\s*([\"`])(.*?)\1", s)
    return [x[1] for x in m]


def outline(path):
    src = open(path, encoding="utf-8").read()
    src = re.sub(r"className=(\"[^\"]*\"|\{[^{}]*(\{[^{}]*\}[^{}]*)*\})", "", src)
    ev = []
    for m in re.finditer(r"<Page\b", src):
        a = src[m.start():tag_end(src, m.start())]
        ev.append((m.start(), "SAYFA", "%s — %s" % (attr(a, "title"), attr(a, "description") or ""), []))
    for m in re.finditer(r"useApi\(\s*\[([^\]]*)\]\s*,\s*([^;]*?)\)\s*;", src):
        ev.append((m.start(), "OKUR", m.group(1).replace('"', "")[:40], calls(m.group(2))))
    for m in re.finditer(r"<(Card|Modal|Notice|NotImplementedNotice)\b", src):
        a = src[m.start():tag_end(src, m.start())]
        t = attr(a, "title")
        if m.group(1) == "Notice":
            e = src.find("</Notice>", m.end())
            ev.append((m.start(), "NOT", (t + ": " if t else "") + text(src[tag_end(src, m.start()) + 1:e]), []))
        elif t:
            ev.append((m.start(), m.group(1).upper(), t, []))
    for m in re.finditer(r"<Tabs\b", src):
        a = src[m.start():tag_end(src, m.start())]
        ev.append((m.start(), "SEKMELER", ", ".join(re.findall(r"label:\s*\"([^\"]+)\"", a)), []))
    for m in re.finditer(r"<Table\b", src):
        a = src[m.start():tag_end(src, m.start())]
        hs = [h for h in re.findall(r"header:\s*\"([^\"]*)\"", a) if h]
        ev.append((m.start(), "TABLO", " | ".join(hs), []))
    for m in re.finditer(r"<FormModal\b", src):
        a = src[m.start():tag_end(src, m.start())]
        e = src.find("</FormModal>", m.end())
        body = src[m.start():e]
        fields = re.findall(r"<Field\s+label=\"([^\"]+)\"([^>]*)", body)
        fl = ", ".join(f[0] + ("*" if "required" in f[1] else "") for f in fields)
        if 'type="file"' in body:
            fl += " [dosya]"
        ev.append((m.start(), "FORM", "%s — alanlar: %s — başarı: %s" % (attr(a, "title"), fl, "; ".join(succ(a))), calls(a)))
    for m in re.finditer(r"<Button\b", src):
        te = tag_end(src, m.start())
        a = src[m.start():te]
        e = src.find("</Button>", te)
        label = text(src[te + 1:e])
        pre = src[max(0, m.start() - 400):m.start()]
        cond = "yalnız yazma yetkisi" if re.search(r"can\w*\s*&&[^&]*$", pre) or re.search(r"can\w+\s*\?[^?]*$", pre) else ""
        what = calls(a)
        opens = re.findall(r"set(\w+)\(", a)
        dl = "indirir" if re.search(r"download|\.pdf|\.xlsx|window\.open", a) else ""
        info = "; ".join(x for x in [cond, ("açar: " + ",".join(opens)) if opens and not what else "", dl, "başarı: " + "; ".join(succ(a)) if succ(a) else "", "onay sorar" if "confirm(" in a else ""] if x)
        ev.append((m.start(), "DÜĞME", "%s%s" % (label or attr(a, "aria-label") or "?", (" (" + info + ")") if info else ""), what))
    for m in re.finditer(r"<(Link|a)\s[^>]*href=(\"[^\"]+\"|\{[^}]+\})", src):
        e = src.find("</%s>" % m.group(1), m.end())
        ev.append((m.start(), "BAĞLANTI", "%s → %s" % (text(src[tag_end(src, m.start()) + 1:e]), m.group(2).strip('"{}')[:60]), []))
    for m in re.finditer(r"type=\"file\"", src):
        ev.append((m.start(), "DOSYA", "dosya seçme alanı", []))
    for m in re.finditer(r"onChange=\{[^}]*\b(api\.\w+\.\w+)", src):
        ev.append((m.start(), "DEĞİŞİMDE", "", [m.group(1)[4:]]))
    ev.sort(key=lambda x: x[0])
    out = []
    for pos, kind, desc, cs in ev:
        out.append("%d %s %s%s" % (line_of(src, pos), kind, desc, (" ⇒ " + ", ".join(cs)) if cs else ""))
    return out


for p in sys.argv[1:]:
    print("##", p)
    print("\n".join(outline(p)))
