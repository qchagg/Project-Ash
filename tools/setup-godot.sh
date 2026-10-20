#!/usr/bin/env bash
# Installs Godot (headless-capable editor) and its web export templates. Safe to re-run.
# Paste this into the cloud environment's Setup script so each session starts with Godot ready.
# godotengine.org's downloads redirect to a host the network policy blocks, so this uses the official GitHub mirror.
set -euo pipefail
V=4.7.2
REL="https://github.com/godotengine/godot-builds/releases/download/$V-stable"
TPL="$HOME/.local/share/godot/export_templates/$V.stable"
if ! godot --version 2>/dev/null | grep -q "^$V.stable"; then
  mkdir -p /opt/godot && cd /opt/godot
  curl -fsSL -o godot.zip "$REL/Godot_v$V-stable_linux.x86_64.zip"
  unzip -oq godot.zip && rm godot.zip
  mv -f "Godot_v$V-stable_linux.x86_64" godot && ln -sf /opt/godot/godot /usr/local/bin/godot
fi
if [ ! -f "$TPL/web_nothreads_release.zip" ]; then
  # The full template bundle is 1.3 GB; keep only the web templates.
  mkdir -p "$TPL" && cd /tmp
  curl -fsSL -o tpl.tpz "$REL/Godot_v$V-stable_export_templates.tpz"
  unzip -joq tpl.tpz 'templates/web*' 'templates/version.txt' -d "$TPL" && rm tpl.tpz
fi
godot --headless --version
