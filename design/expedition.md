# Expedition: the run

The centre tab. You choose a road, set out with the party, and walk a branching map one stop at a time, like
Honkai: Star Rail's Simulated Universe (or Slay the Spire). Rules live in `game/core/expedition.gd` (checked in
`game/tests/run_checks.gd`); the screen is `game/ui/expedition_screen.gd`.

## Roads

| Road | Region | Element | Danger | Stops |
|---|---|---|---|---|
| The Basalt Steps | Hraunvald | earth | 1 | 7 |
| The Drowned Ghats | Jaladesh | water | 2 | 8 |
| The Saltglass Road | Marusthal | fire | 3 | 9 |

Each road has a home foe (golem, tidecaller, seer) that is in every fight there. Danger scales foes and embers.

## The map

Layers of two or three stops; each stop leads to the nearest one or two ahead, and every stop is reachable. The first
layer is always fights, a camp always comes just before the warden, and no elite or camp comes before the third layer.

| Stop | What happens |
|---|---|
| Skirmish | A fight: two foes early, three later. |
| Elite | Three foes, +20% tougher; rarer rewards. |
| Camp | Everyone standing heals a share of max health: 30%, more with each Infirmary level (100% at 5). |
| Boon | Choose one of three blessings for the rest of the run (attack, defense, speed, health, element attack, embers). |
| Cache | Embers; rare or better also leaves an augment. |
| Trial | A hero rolls d20 on an aptitude (+3 if favored) against 12; success pays embers. |
| Warden | Four foes, +35% tougher. Beat it to clear the road. |

Boons and caches have a rarity: common, rare, epic, legendary (60 / 28 / 10 / 2); elites and the warden roll one
step better.

## Carrying over

- Health carries from fight to fight. A hero knocked out stays down for the rest of the run.
- Embers gathered on the road go to the town when the run ends: all of them on a clear or a turn for home, half if
  the squad falls.
- Boons end with the run.

## Open questions

- Should a fallen hero be revivable at a camp (at a cost), or only by the Infirmary back home?
- Do boons need downsides at legendary (a curse slot), or stay purely positive?
- Should skills learned at level-up come from boon-like offers here (the rarity ladder is the same)?
- Is the road random each time, or a fixed map per road that you learn?
