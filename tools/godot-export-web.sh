#!/usr/bin/env bash
# Exports the Godot game for the web into build/web/, ready to publish as the playtest artifact.
# Artifacts serve only web file types, binaries up to 15 MB and text up to 16 MB. The engine (index.wasm, ~40 MB)
# and the game pack (index.pck) therefore ship as gzipped base64 text, which a fetch wrapper in the page shell
# (game/web/shell.html) unpacks in the browser.
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf build/web && mkdir -p build/web
(cd game && godot --headless --import >/dev/null 2>&1 || true; godot --headless --export-release "Web" ../build/web/index.html >/dev/null 2>&1)
for f in index.wasm index.pck; do gzip -9 -c build/web/$f | base64 -w0 > build/web/$f.gz.b64.txt && rm build/web/$f; done
rm build/web/index.png build/web/index.icon.png build/web/index.apple-touch-icon.png
ls -la build/web
