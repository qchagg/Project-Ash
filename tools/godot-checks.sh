#!/usr/bin/env bash
# Runs the Godot port's acceptance checks headless. Exits non-zero if any fail.
set -euo pipefail
cd "$(dirname "$0")/../game"
godot --headless --import >/dev/null 2>&1 || true   # builds .godot/ (class names, imported art) on a fresh checkout
timeout 300 godot --headless -s tests/run_checks.gd
timeout 300 godot --headless -s tests/compile_all.gd
