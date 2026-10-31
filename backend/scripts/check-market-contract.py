#!/usr/bin/env python3
"""Pazaryeri uçları sözleşme belgesinde mi? (FAZ M2.8)

services/marketplace'in kaydettiği her rota ve kimlik servisinin tedarikçi kaydı/konum uçları
tasks/api-sozlesmesi.md'de "`METHOD /yol`" biçiminde geçmelidir. Belgede olmayan uç = sözleşmesiz uç.
"""
import importlib.util, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("cgr", os.path.join(HERE, "check-gateway-routes.py"))
cgr = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cgr)
DOC = open(os.path.join(HERE, "..", "..", "tasks", "api-sozlesmesi.md"), encoding="utf-8").read()

routes = set(cgr.service_routes("marketplace"))
routes |= {r for r in cgr.service_routes("identity") if "/supplier-signup/" in r[1] or r[1].endswith("/property/location")}
missing = []
for method, path in sorted(routes):
    p = re.sub(r"^/api/v1", "", path)
    if not re.search(r"`" + method + r" " + re.escape(p) + r"`", DOC):
        missing.append("%s %s" % (method, p))
if missing:
    print("Sözleşmede olmayan uçlar:\n  " + "\n  ".join(missing))
    sys.exit(1)
print("pazaryeri sözleşmesi tam: %d uç" % len(routes))
