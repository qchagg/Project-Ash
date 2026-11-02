# Expedition: the run

The centre tab. You choose a road, set out with the party, and walk a branching map one stop at a time, like
Honkai: Star Rail's Simulated Universe (or Slay the Spire). Rules live in `game/core/expedition.gd` (checked in
`game/tests/run_checks.gd`); the screen is `game/ui/expedition_screen.gd`.

## Roads

| Road | Region | Element | Danger | Stops |
|---|---|---|---|---|
| The Basalt Steps | Hraunvald | earth | 1 | 7 |
| The Aqueduct | Jaladesh | water | 2 | 8 |
| The Saltglass Road | Marusthal | fire | 3 | 9 |
| The Standing Stones | Gwyntmoor | wind | 1 | 7 |
| The Empty Pavilions | Mehfil | fire | 2 | 8 |
| The Walking Wood | Vetrolés | wind | 2 | 8 |
| The Serpent Archive | Yuling | wind | 3 | 9 |
| The Veiled Undercroft | Velata | fire | 3 | 9 |
| The Whale Cathedral | Sikuvik | water | 3 | 9 |

Each road is the ruin of a home on the city atlas, and it has a home foe (golem, tidecaller, seer, galeblade) that is in every fight there. Danger scales foes and embers.
The Aqueduct took the Drowned Ghats' place.

A road card is its painting, with the region's colour washing in behind the badge and the words low on the card. Each
road names its painting in `art`.

Gold is the common currency (still `embers` in the code), and Stardust will be the premium one. Nothing is paid.

## Music

Each road names its tracks in `music` on `Expedition.ROADS`: one for the map and one for each kind of stop. They were
chosen on the [Road Music board](https://claude.ai/artifact/Nod2YCoKMYeXhBW9tZfsBM).

| Road | Map | Elite and Wayside |
|---|---|---|
| The Basalt Steps | Celestial Path | Celestial Path |
| The Aqueduct | Ash and Oasis | Canyon Echoes |
| The Saltglass Road | Scorchlight Mirage | Whispers in the Sand |
| The Standing Stones | Pale Waters | Pale Waters, intense part |
| The Empty Pavilions | Whispers in the Sand | Canyon Echoes |
| The Walking Wood | Celestial Path | Pale Waters, intense part |
| The Serpent Archive | Pale Waters | Canyon Echoes |
| The Veiled Undercroft | Scorchlight Mirage | Canyon Echoes |
| The Whale Cathedral | Celestial Path | Pale Waters, intense part |
| Shared default | Pale Waters (full) | Pale Waters (intense part) |

A slot with no track uses the shared default, then the road's map track, so skirmishes, wardens, camps and
boons stay on the map music until they get their own. Menu tracks live in the shared default too: `menu` is Sunblade Horizon (the title
screen and the road choice), `heroes` is Dunes of Silence and `town` is Frostfire Tales. Heroes and Town play
theirs on or off a run; the board keeps menu picks under its Menus entry. The board also holds picks for the Drowned Ghats (Whispers Beyond,
Echoed Blades), which are not in the game.

## The map

Layers of two or three stops; each stop leads to the nearest one or two ahead, and every stop is reachable. The first
layer is always fights, a camp always comes just before the warden, and no elite or camp comes before the third layer.

| Stop | What happens |
|---|---|
| Skirmish | A fight: two foes early, three later. |
| Elite | Three foes, +20% tougher; rarer rewards. |
| Camp | Everyone standing heals a share of max health: 30%, more with each Infirmary level (100% at 5). |
| Boon | Choose one of three blessings for the rest of the run (attack, defense, speed, health, element attack, embers). |
| Wayside | An unknown stop: a short scene, two or three choices, a one-line outcome. See `design/events.md`. |
| Warden | Four foes, +35% tougher. Beat it to clear the road. |

Boons and Wayside stops have a rarity: common, rare, epic, legendary (60 / 28 / 10 / 2); elites and the warden roll one
step better.

## Hero picks

After every won fight except the warden, one standing hero is offered up to three upgrades for the rest of the run.
The offers go round the squad: the standing hero with the fewest offers so far is next, in squad order.

- A pick is an augment bound to one of that hero's skills. The fallen are passed over.
- Each option rolls the boon rarity odds, then takes the nearest tier that has something: common Keen, Wellspring and
  Bulwark; rare Hasten, Kindling and Lingering; epic Celerity. Elites roll one step better.
- The same augment on the same skill never appears twice in an offer, and nothing useless is offered: no second
  Celerity on a hero, no Hasten at cooldown 1, no Kindling on what already burns, no second Lingering on a skill.
- Each offer earns one free reroll, and unused ones are saved. With none in hand a reroll costs 20 embers, doubling on
  the same offer up to 320; the price resets with the next offer.
- A hero holds two picks on a road. Past that, a new pick replaces one the player chooses.
- Skipping pays a quarter of a skirmish's purse.

`#event-pick` opens an offer straight away. The numbers are first guesses and have not been playtested.

## Carrying over

- Health carries from fight to fight. A hero knocked out stays down for the rest of the run.
- Embers gathered on the road go to the town when the run ends: all of them on a clear or a turn for home, half if
  the squad falls.
- Boons and hero picks end with the run.

## Open questions

- Should a fallen hero be revivable at a camp (at a cost), or only by the Infirmary back home?
- Do boons need downsides at legendary (a curse slot), or stay purely positive?
- Should hero picks ever offer new skills, not only upgrades to the ones a hero has?
- Is the road random each time, or a fixed map per road that you learn?
