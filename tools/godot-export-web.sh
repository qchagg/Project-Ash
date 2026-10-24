#!/usr/bin/env bash
# Exports the Godot game for the web, ready to publish as a playtest artifact:
#   tools/godot-export-web.sh            the phone build (portrait) into build/web/
#   tools/godot-export-web.sh landscape  the wide build (the "landscape" feature) into build/web-landscape/
# Artifacts serve only web file types, binaries up to 15 MB and text up to 16 MB. The engine (index.wasm, ~40 MB)
# and the game pack (index.pck) therefore ship as gzipped base64 text, which a fetch wrapper in the page shell
# (game/web/shell.html) unpacks in the browser.
set -euo pipefail
cd "$(dirname "$0")/.."
preset="Web"; out="build/web"
if [ "${1:-}" = "landscape" ]; then preset="Web Landscape"; out="build/web-landscape"; fi
rm -rf "$out" && mkdir -p "$out"
(cd game && godot --headless --import >/dev/null 2>&1 || true; godot --headless --export-release "$preset" "../$out/index.html" >/dev/null 2>&1)
for f in index.wasm index.pck; do gzip -9 -c "$out/$f" | base64 -w0 > "$out/$f.gz.b64.txt" && rm "$out/$f"; done
# Hero clips stay out of the pack (see game/ui/clips.gd): they ship beside the page and load as they're wanted.
mkdir -p "$out/clips" && for f in game/art/clips/*.ogv; do b=$(basename "$f" .ogv); cp "$f" "$out/clips/$b.ogg"; done
rm -f "$out/index.png" "$out/index.icon.png" "$out/index.apple-touch-icon.png"
if [ "$preset" = "Web Landscape" ]; then sed -i 's|<title>Ashgrid Playtest|<title>Ashgrid Landscape|' "$out/index.html"; fi
ls -la "$out"
