# Project Ash (working title: Ashgrid)

A turn-based squad battler with a roguelite run structure. You queue your heroes' actions in order (from Seven Knights) on a grid where position, lanes and range shapes matter (from Enchanted Arms). Heroes are cards that merge up in stars and take elemental augments. No monetization of any kind.

- **Godot playtest:** [Ashgrid Playtest](https://claude.ai/artifact/9BKdbsQVseK1YN7DhY1CKw) (the real game, built in Godot 4.7, playable in the browser)
- **Playable sandbox:** [Ashgrid Combat Sandbox](https://claude.ai/artifact/Ln4qNwpjb9wkEykWCy2ShL) (the rules prototype the game is ported from)
- **Design tracker:** [Ashgrid — Game Design Tracker](https://claude.ai/code/artifact/5425ff38-fc13-4ad2-99de-10ba5c00adea) (decisions, rules, backlog)

## What's here

| Path | What it is |
| --- | --- |
| `game/` | The Godot 4.7 project. Open `game/project.godot` in the Godot editor and press Play. |
| `game/core/` | Game rules in GDScript (`data.gd`, `collection.gd`), ported from the sandbox. |
| `game/ui/` | Screens. `collection.tscn` is the Collection with merging and the Ashcrown. |
| `game/tests/run_checks.gd` | The Godot acceptance checks. |
| `sandbox/index.html` | The combat prototype: one self-contained page. Open it in a browser. |
| `sandbox/portraits/` | Character portraits the sandbox loads (1024×1024 webp). |
| `art/` | Drop new and source art here; see `art/README.md` for the specs. |
| `design/icons/` | Element glyphs as SVG (fire, water, earth, wind), plus the directions explored. |
| `design/` | Reference images for design decisions. |
| `tools/` | Headless scripts: acceptance checks and the fight simulator. |

## Core systems (as of 2026-10-20)

- **Elements:** Water douses Fire → Fire consumes Wind → Wind erodes Earth → Earth dams Water. Opposites are neutral.
- **Cards:** every copy of a hero rolls its own stats. Two cards of the same star level merge one star up (to 3★); an Ashcrown boss drop makes a 4★. Merged stats keep the best of each, +10% per star.
- **Augments:** one slot per star. Augments are elemental spirits (Salamander, Undine, Gnome, Sylph) that boost a skill, rename it and give the card an aura. They swap freely until a merge locks them.

## Working on the Godot game

Install [Godot 4.7.2](https://godotengine.org/download) (the standard build, not .NET), open `game/project.godot`, and press Play (F5). The editor's Play window is 720×1280, a phone held upright.

```sh
tools/setup-godot.sh         # installs Godot and the web export templates (the cloud environment's Setup script runs this)
tools/godot-checks.sh        # the Godot acceptance checks, headless; exits 1 on any failure
tools/godot-export-web.sh    # builds build/web/, the playtest that is published as an artifact
```

## Running the sandbox checks

Needs Node and Playwright (`npm i -D playwright`, then `npx playwright install chromium`).

```sh
node tools/run-checks.js     # all acceptance checks; exits 1 on any failure
node tools/simulate.js       # the fixed fight under each element mode and rule set
```

The sandbox also runs the same checks in the browser: Acceptance checks → Run checks.
