# Working on Project Ash

- The game is the Godot 4.7 project in `game/`, and it is the source of truth for every rule and screen. Build new work there directly; rules live in `game/core/`. Comments and naming follow GDScript style (snake_case, tabs, `##` doc comments).
- Build every screen from `game/ui/forge.gd`: its palette, Alegreya Sans SC set in lowercase (even small caps), `art/icons/ui/` glyphs, and the button roles (studs commit, at most one per screen; ember is everyday; links move). Don't style controls inline.
- Run `tools/godot-checks.sh` before committing Godot changes; every check must pass. Add a check for each new rule. The two reference fights replay in these checks and must not change.
- After changing the game, run `tools/godot-export-web.sh` and republish `build/web/index.html` (with its files) to https://claude.ai/artifact/9BKdbsQVseK1YN7DhY1CKw. `build/` is not committed.
- The same game also exports wide: `tools/godot-export-web.sh landscape` (the "landscape" feature turns the viewport to 1560×720; `Forge.wide()` is true) into `build/web-landscape/`, published at https://claude.ai/artifact/PLCWSdFwiUZ6o9GXhV1Avn. Keep both layouts working when you change a screen. The two builds are two directions: the phone build shows heroes as cards; the landscape build shows them as battle sprites (Figure in ui/figure.gd, Stand in ui/stand.gd, BattleFigure on the battle board). Sprites and their sizes are `Data.SPRITES`; new sprite art goes through `tools/sprite-cutout.py` and imports lossy.
- The app owns the nav (Heroes · Expedition · Town); screens set `tab` and fill their body. Expedition rules: `design/expedition.md`; town: `design/town.md`. Playtest links ending `#event-boon` (camp, cache, trial, fight, warden), `#town` or `#heroes` open straight there.
- Use `Rim` (ui/rim.gd) for animated borders: comet for what you can act on, flow for what is chosen, pulse for the commit.
- If Godot is missing in a fresh session, run `tools/setup-godot.sh`.
- The sandbox (`sandbox/index.html`, published at https://claude.ai/artifact/Ln4qNwpjb9wkEykWCy2ShL) is frozen as the record of the v0.1 rules and the two reference fights. Don't add new rules to it.
- Design decisions live in the Docs tracker (https://claude.ai/code/artifact/5425ff38-fc13-4ad2-99de-10ba5c00adea). Log decisions there, newest first in the decisions table.
- The user is learning French: a short French line with its English translation is welcome in replies.
