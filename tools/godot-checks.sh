#!/usr/bin/env bash
# Runs the Godot port's acceptance checks headless. Exits non-zero if any fail or any script fails to compile.
set -euo pipefail
cd "$(dirname "$0")/../game"
godot --headless --import >/dev/null 2>&1 || true   # builds .godot/ (class names, imported art) on a fresh checkout
log="$(mktemp)"
trap 'rm -f "$log"' EXIT
status=0
timeout 300 godot --headless -s tests/run_checks.gd 2>&1 | tee "$log" || status=1
timeout 300 godot --headless -s tests/compile_all.gd 2>&1 | tee -a "$log" || status=1
if grep -q "SCRIPT ERROR" "$log"; then
	echo "Script errors above: the checks did not run cleanly." >&2
	status=1
fi
exit $status
