# Working on Project Ash

- The game is the Godot 4.7 project in `game/`. Rules live in `game/core/` and are ported from the sandbox; keep the two in step until the sandbox retires. Comments and naming follow GDScript style (snake_case, tabs, `##` doc comments).
- Build every screen from `game/ui/forge.gd`: its palette, Alegreya Sans SC set in lowercase (even small caps), `art/icons/ui/` glyphs, and the button roles (studs commit, at most one per screen; ember is everyday; links move). Don't style controls inline.
- Run `tools/godot-checks.sh` before committing Godot changes; every check must pass. Port each sandbox check when its system is ported, and add a check for each new rule.
- After changing the game, run `tools/godot-export-web.sh` and republish `build/web/index.html` (with its files) to https://claude.ai/artifact/9BKdbsQVseK1YN7DhY1CKw. `build/` is not committed.
- If Godot is missing in a fresh session, run `tools/setup-godot.sh`.
- The sandbox is `sandbox/index.html`, a single page with no build step. Keep it self-contained.
- It is published as the artifact https://claude.ai/artifact/Ln4qNwpjb9wkEykWCy2ShL. After changing it, republish to that URL so the link stays the same, and commit the same file here.
- Design decisions live in the Docs tracker (https://claude.ai/code/artifact/5425ff38-fc13-4ad2-99de-10ba5c00adea). Log decisions there, newest first in the decisions table.
- Run `node tools/run-checks.js` before committing; every check must pass. The two reference fights replay under the v0.1 element triangle and must not change.
- Add an acceptance check to `CHECKS` in the sandbox for each new rule or system.
- The user is learning French: a short French line with its English translation is welcome in replies.
