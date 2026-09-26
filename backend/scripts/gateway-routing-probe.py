#!/usr/bin/env python3
"""Gateway yönlendirmesini ÇALIŞMA ANINDA sınar (saplama sunucularıyla).

check-gateway-routes.py tabloyu statik olarak denetler; bu araç ise gerçek
gateway ikilisinin isteği gerçekten doğru adrese ilettiğini ölçer (ön ek /
eğik çizgi eşleşmesi, yol korunumu, kimlik başlığı).

  serve <taban_port>   : her servis için taban+i portunda, gelen isteğe
                         {"service": ad, "path": yol} dönen saplama açar.
                         Gateway'in *_SERVICE_URL değişkenlerini stdout'a yazar.
  probe <gateway_url> <jeton> : her servisin her rotası için gateway'e istek
                         atar; yanıtın DOĞRU servisten ve DOĞRU yolla geldiğini
                         denetler.
"""
import importlib.util
import json
import os
import re
import sys
import threading
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))


def load(name, file):
    spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, file))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


gd = load("gd", "gen-deploy.py")
cg = load("cg", "check-gateway-routes.py")
SERVICES = [s[0] for s in gd.SERVICES]


def serve(base):
    servers = []
    for i, svc in enumerate(SERVICES):
        class H(BaseHTTPRequestHandler):
            name = svc

            def _reply(self):
                body = json.dumps({"service": self.name, "path": self.path.split("?")[0],
                                   "auth": bool(self.headers.get("Authorization"))}).encode()
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            do_GET = do_POST = do_PUT = do_PATCH = do_DELETE = _reply

            def log_message(self, *a):
                pass

        srv = ThreadingHTTPServer(("127.0.0.1", base + i), H)
        threading.Thread(target=srv.serve_forever, daemon=True).start()
        servers.append(srv)
        print(f"{gd.GATEWAY_ENV[svc]}=http://127.0.0.1:{base + i}", flush=True)
    print("READY", flush=True)
    threading.Event().wait()


def probe(gateway, token):
    bad, total = [], 0
    for svc in SERVICES:
        for method, path in sorted(cg.service_routes(svc)):
            real = re.sub(r":\w+", "00000000-0000-0000-0000-000000000000", re.sub(r"\*\w+", "x", path))
            method = "GET" if method == "Any" else method
            req = urllib.request.Request(gateway + real, method=method,
                                         data=b"{}" if method in ("POST", "PUT", "PATCH") else None,
                                         headers={"Authorization": "Bearer " + token,
                                                  "Content-Type": "application/json"})
            total += 1
            try:
                with urllib.request.urlopen(req, timeout=5) as r:
                    got = json.loads(r.read())
            except Exception as e:  # noqa: BLE001
                bad.append(f"{svc:16} {method:6} {path}  → istek başarısız: {e}")
                continue
            if got.get("service") != svc:
                bad.append(f"{svc:16} {method:6} {path}  → YANLIŞ SERVİS: {got.get('service')}")
            elif got.get("path") != real:
                bad.append(f"{svc:16} {method:6} {path}  → yol değişmiş: {got.get('path')}")
            elif not got.get("auth"):
                bad.append(f"{svc:16} {method:6} {path}  → kimlik başlığı iletilmedi")
    if bad:
        print("\n".join(bad))
        print(f"{len(bad)}/{total} rota hatalı")
        return 1
    print(f"{total} rotanın tamamı gateway üzerinden doğru servise ulaştı")
    return 0


if __name__ == "__main__":
    if sys.argv[1] == "serve":
        serve(int(sys.argv[2]))
    else:
        sys.exit(probe(sys.argv[2], sys.argv[3]))
