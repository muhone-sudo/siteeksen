#!/usr/bin/env python3
"""Gateway yönlendirme tablosunun servislerin GERÇEK rotalarını kapsadığını denetler.

NEDEN VAR (2026-09-26): verify-stack servisleri doğrudan kendi portlarından
sınıyordu; gateway'in isteği doğru servise iletip iletmediği hiç ölçülmüyordu.
Ölçüldüğünde ayarlar, devriye, ilan panosu, sayaç okuma, demirbaş/stok/kargo
özetleri ve bildirim tercihleri gibi rotaların gateway'de HİÇ tanımlı olmadığı
ortaya çıktı: tek giriş kapısının arkasındaki üretim ortamında bu modüller
erişilemezdi. Bu betik:

  1. Her servisin main.go'sundaki gin grup ve rota kayıtlarını çözer,
  2. cmd/gateway/main.go'daki yönlendirme tablosunu okur,
  3. Her rotanın gateway'de bir ön eke düştüğünü VE doğru servise gittiğini
     denetler; ayrıca hiçbir servise karşılık gelmeyen ölü ön ekleri raporlar.

Çıkış kodu 0: tutarlı. 1: eksik ya da yanlış yönlendirme var.
"""
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SERVICES = os.path.join(ROOT, "services")
GATEWAY = os.path.join(ROOT, "cmd", "gateway", "main.go")

GROUP = re.compile(r"(\w+)\s*:=\s*(\w+)\.Group\(\"([^\"]*)\"")
ROUTE = re.compile(r"\b(\w+)\.(GET|POST|PUT|PATCH|DELETE|Any)\(\"([^\"]*)\"")


def service_routes(name):
    # main paketinin bütün dosyaları (rota kaydı main.go dışına da taşınabilir,
    # ör. community/kvkk.go). Grup değişken adları dosyaya özeldir.
    d = os.path.join(SERVICES, name)
    out = set()
    for fn in sorted(os.listdir(d)):
        if not fn.endswith(".go") or fn.endswith("_test.go"):
            continue
        src = open(os.path.join(d, fn), encoding="utf-8").read()
        if not src.lstrip().startswith("package main") and "\npackage main" not in src:
            continue
        prefix = {"r": ""}
        for var, parent, path in GROUP.findall(src):
            prefix[var] = prefix.get(parent, "") + path
        for var, method, path in ROUTE.findall(src):
            full = prefix.get(var, "") + path
            if full.startswith("/api/v1/"):
                out.add((method, full))
    return out


def gateway_table():
    """proxyRoute(...) / routes tablosunu okur: env adı → ön ekler."""
    src = open(GATEWAY, encoding="utf-8").read()
    envvar = dict(re.findall(r"(\w+)\s*:=\s*getEnv\(\"(\w+_SERVICE_URL)\"", src))
    table = {}
    for var, body in re.findall(r"\{\s*(\w+URL),\s*\[\]string\{([^}]*)\}\s*\}", src):
        prefixes = re.findall(r"\"([^\"]+)\"", body)
        table.setdefault(envvar[var], []).extend(prefixes)
    return table


def env_for(service):
    # gen-deploy.py ile aynı eşleme (tek kaynak orası; burada okunur).
    sys.path.insert(0, os.path.dirname(__file__))
    import importlib.util
    spec = importlib.util.spec_from_file_location("gd", os.path.join(os.path.dirname(__file__), "gen-deploy.py"))
    gd = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gd)
    return gd.GATEWAY_ENV[service]


def covers(prefix, path):
    return path == prefix or path.startswith(prefix + "/")


def main():
    table = gateway_table()
    if not table:
        print("gateway yönlendirme tablosu okunamadı")
        return 1
    problems = []
    used = set()
    total = 0
    for svc in sorted(os.listdir(SERVICES)):
        if not os.path.isfile(os.path.join(SERVICES, svc, "main.go")):
            continue
        env = env_for(svc)
        mine = table.get(env, [])
        for method, path in sorted(service_routes(svc)):
            total += 1
            # Gin yol parametresini (:id) gerçek bir değerle sına
            probe = re.sub(r":\w+", "x", re.sub(r"\*\w+", "x", path))
            hits = [(e, p) for e, ps in table.items() for p in ps if covers(p, probe)]
            if not hits:
                problems.append(f"YÖNLENDİRİLMİYOR  {svc:16} {method:6} {path}")
                continue
            # En uzun eşleşen ön ek kazanır (ServeMux davranışı)
            env_hit, pref = max(hits, key=lambda h: len(h[1]))
            used.add(pref)
            if env_hit != env:
                problems.append(f"YANLIŞ SERVİS     {svc:16} {method:6} {path} → {env_hit}")
    for env, ps in table.items():
        for p in ps:
            if p not in used:
                problems.append(f"ÖLÜ ÖN EK         {p} ({env}) — hiçbir servis rotası buraya düşmüyor")
    if problems:
        print("\n".join(problems))
        print(f"\n{len(problems)} sorun ({total} rota denetlendi)")
        return 1
    print(f"gateway tutarlı: {total} rota, {sum(len(v) for v in table.values())} ön ek")
    return 0


if __name__ == "__main__":
    sys.exit(main())
