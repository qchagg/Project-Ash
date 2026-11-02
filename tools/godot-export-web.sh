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
# Only the playable heroes' clips ship; faces of characters not in the game yet wait in the Asset Viewer.
mkdir -p "$out/clips"
for b in $(python3 -c '
import re
heroes = set(re.findall(r"\{\"key\": \"(\w+)\"", open("game/core/data.gd").read()))
for key, body in re.findall(r"^\t\"(\w+)\": (\{.*\}),$", open("game/core/faces.gd").read(), re.M):
    if key in heroes:
        print(" ".join(set(re.findall(r"\"(\w+-\w+)\"", body))))
' | tr -d '\r'); do cp "game/art/clips/$b.ogv" "$out/clips/$b.ogg"; done
# Idle frame sheets and painted backgrounds stay out of the pack too, and load the same way.
mkdir -p "$out/sheets" && cp game/art/sprites/*-idle.webp game/art/sprites/*-attack.webp game/art/backgrounds/*.webp game/art/grounds/*.webp game/art/stands/*.webp game/audio/voice/*.wav "$out/sheets/"
# Music stays out of the pack and out of git (see game/ui/music.gd): the chosen tracks in game/audio/music/ ship beside
# the page, and the export fails if one is missing.
mkdir -p "$out/music"
for t in $(grep -oE '"(jrpg|fairytale|desert|pirate)-[a-z0-9-]+"' game/core/expedition.gd | tr -d '"\r' | sort -u); do cp "game/audio/music/$t.ogg" "$out/music/"; done
rm -f "$out/index.png" "$out/index.icon.png" "$out/index.apple-touch-icon.png"
if [ "$preset" = "Web Landscape" ]; then sed -i 's|<title>A Thousand Roads|<title>A Thousand Roads Landscape|' "$out/index.html"; fi
ls -la "$out"
