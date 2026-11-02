#!/usr/bin/env bash
# Prepares a git worktree of this repo: copies in the licensed audio that git must not hold, then imports the project.
# Run from the worktree: bash tools/setup-fork.sh
set -e
main=$(git worktree list --porcelain | head -1 | cut -d' ' -f2-)
here=$(git rev-parse --show-toplevel)
if [ "$main" = "$here" ]; then echo "This is the main folder; nothing to copy."; exit 0; fi
mkdir -p "$here/game/audio/music" "$here/game/audio/sfx"
cp -u "$main"/game/audio/music/*.ogg "$here/game/audio/music/"
cp -u "$main"/game/audio/sfx/*.ogg "$main"/game/audio/sfx/*.wav "$here/game/audio/sfx/"
command -v godot >/dev/null || export PATH="$TEMP/godot-bin:$PATH"
(cd "$here/game" && godot --headless --import >/dev/null 2>&1) || true
echo "Audio copied from $main and project imported."
