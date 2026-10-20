# Project Ash (working title: Ashgrid)

A turn-based squad battler with a roguelite run structure. You queue your heroes' actions in order (from Seven Knights) on a grid where position, lanes and range shapes matter (from Enchanted Arms). Heroes are cards that merge up in stars and take elemental augments. No monetization of any kind.

- **Playable sandbox:** [Ashgrid Combat Sandbox](https://claude.ai/artifact/Ln4qNwpjb9wkEykWCy2ShL)
- **Design tracker:** [Ashgrid — Game Design Tracker](https://claude.ai/code/artifact/5425ff38-fc13-4ad2-99de-10ba5c00adea) (decisions, rules, backlog)

## What's here

| Path | What it is |
| --- | --- |
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

## Running the checks

Needs Node and Playwright (`npm i -D playwright`, then `npx playwright install chromium`).

```sh
node tools/run-checks.js     # all acceptance checks; exits 1 on any failure
node tools/simulate.js       # the fixed fight under each element mode and rule set
```

The sandbox also runs the same checks in the browser: Acceptance checks → Run checks.
