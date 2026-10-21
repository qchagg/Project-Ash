# Town: the meta-progression hub

The centre tab. Between fights the squad comes home to a town that grows around a fire. Rules live in
`game/core/town.gd` (checked in `game/tests/run_checks.gd`); the screen is `game/ui/town_screen.gd`.

## The loop

1. **Fight** → a won battle brings home **embers** (120, +10% per Hearth level past the first).
2. **Build** → embers raise buildings one level at a time. Each level opens something in another system.
3. **Grow the Hearth** → no building can rise above the **Ashen Hearth**, so the Hearth paces the whole town.
4. **Go back out stronger** → better merges, more augments, new heroes on the road, favors from envoys.

Embers are the only town resource. Ashcrowns and augments stay card-side (roster/equip); the town decides
what you *can* do with them, not how many you have.

## Buildings

| Building | Feeds | Levels give |
|---|---|---|
| Ashen Hearth (max 6) | everything | the level cap for every other building; +10% embers per level |
| The Forge (5) | roster: evolve | merge → merge preview → smelt spare 3★ into Ashcrown shards → 3 shards set a crown → reforge a set augment |
| The Archive (5) | codex, chronicle | lore & home → bonds → scars → regional histories → chronicles of fallen foes |
| Caravanserai (5) | new heroes | trade routes to regions (two at level 1, one per level after, all at 5); heroes arrive along open routes |
| Training Grounds (5) | squad: trials | favored d20 +3 → spar an unfavored aptitude to +1 → +2 → bonded mentors → favored sparks on 18–20 |
| Spirit Bazaar (5) | equip: augments | one spirit family per level (Salamander, Undine, Gnome, Sylph) → rebinding |
| Hall of Envoys (6) | battle, trials | one envoy per region, each with a team-wide favor (e.g. Khorvan: a hero's first move each battle is free) |

Costs start at 100–200 and grow ×1.6 a level, rounded to tens.

## Tone

New heroes **arrive** along routes you chose to open; they are travellers, not pulls. No timers, no
daily chores, no "collect" spam: a building does its thing the moment it rises.

## Prototype notes

- The town lives on `App.town` for the session; nothing saves yet.
- Battles don't pay embers yet; the screen has a playtest "gather embers" button. The Battle prototype should
  call `app.town.earn(app.town.battle_reward())` on a win.
- Only the level rules are real. Building effects (merge preview, shards, sparring, favors) are described,
  not yet wired into their systems.

## Open questions

- How does a hero actually arrive at the Caravanserai: after N battles, after a trial on the road, or by
  choosing from a short list of travellers on an open route?
- Should the player choose which envoy takes each seat (order is fixed by region today)?
- Does the town look different per region you've opened (banners, colorways on the skyline)?
- With five on a team as the target, does a building raise squad size (the Hearth at 6?), or is it fixed?
- Is one resource enough once battles pay out, or do rarer upgrades need a second (e.g. relics from bosses)?
