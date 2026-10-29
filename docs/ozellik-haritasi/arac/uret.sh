#!/usr/bin/env bash
# Özellik haritasını koddan yeniden üretir: bash docs/ozellik-haritasi/arac/uret.sh
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
A="$ROOT/docs/ozellik-haritasi/arac"
# HARITA_WORK verilirse ara dosyalar (rota, çağrı grafiği, özetler) orada kalır.
if [ -n "${HARITA_WORK:-}" ]; then W="$HARITA_WORK"; mkdir -p "$W"; else W=$(mktemp -d); trap 'rm -rf "$W"' EXIT; fi
export PATH=$PATH:/usr/local/go/bin
cd "$ROOT"

python3 -I "$A/routes.py" "$ROOT/backend" "$W/routes.json"
(cd "$A/cg" && go build -o "$W/cg" .)
(cd "$ROOT/backend" && go list -export -deps -json ./services/... ./pkg/... 2>/dev/null) | "$W/cg" "$W/routes.json" "$ROOT/backend" > "$W/cg.json"
python3 -I "$A/endpoints.py" "$ROOT/admin/src/lib/endpoints.ts" "$W/routes.json" "$W/panel_ep.json" >/dev/null
python3 -I "$A/triggers.py" "$ROOT/backend/migrations" "$W/triggers.json" >/dev/null
python3 -I "$A/consumers.py" "$ROOT" "$W"
(cd "$ROOT/admin/src" && python3 -I "$A/outline.py" $(find app -name page.tsx | sort) $(find components -name '*.tsx' ! -path '*/ui/*' | sort)) > "$W/panel_outline.txt"
python3 -I "$A/dart_outline.py" "$W/mobile_named.json" mobile $(find mobile/lib/features mobile/lib/core/widgets -name '*.dart' | sort) > "$W/mobile_outline.txt"
python3 -I "$A/dart_outline.py" "$W/mobile_named.json" admin_app $(find admin_app/lib/features admin_app/lib/core/widgets -name '*.dart' | sort) > "$W/adminapp_outline.txt"
python3 -I "$A/gen.py" "$ROOT" "$W" "$ROOT/docs/ozellik-haritasi"
python3 -I "$A/test_plani.py" "$ROOT" "$W" "$ROOT/docs/test-plani"
