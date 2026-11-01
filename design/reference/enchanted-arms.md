# Enchanted Arms — reference notes

What we learn from studying Enchanted Arms (2006): how its battles flow and why they feel the way they do, written in
our own words. This file is for understanding, not copying: no decompiled code, no verbatim data tables, skill names
or dialogue go into Ashgrid. We read how a mechanic works, note why it works, then design our own version.

Filled in from the EnchantedArms Ghidra project. Each section ends with **For Ashgrid**: what we might take, change or
avoid. Mark anything uncertain with *(unconfirmed)*.

## 1. A turn, start to finish
- The order of a round, step by step: who chooses when, who acts when, what resolves between actions.
- How turn order is decided (speed stat, fixed side order, initiative roll…). Does it change mid-fight?
- What a player can do on a turn: move, act, both, how far.
- What ends a round; what carries over to the next (cooldowns, statuses, positions).

**For Ashgrid:** we plan every hero's step and action, then resolve in queue order; foes act after (Combat core in the
tracker). Where does EA's order make choices more interesting than ours?

## 2. The grid and aiming
- Grid size per side; can units move onto the other side; blocked tiles.
- How a skill's area is described (shapes relative to the caster? to the target? fixed lanes?).
- How aiming works for single, line, cross, area and all-tile skills; what needs line of sight or a front row.
- How range is measured.

**For Ashgrid:** we use lane and shape targeting, a Reach rule for melee, and Ground targeting for areas.

## 3. Skills
- How many skills a unit carries; how they're learned or unlocked.
- Costs: EP/MP, cooldowns, HP costs, charge-ups. Typical cost against typical damage.
- Kinds: damage, heal, buff, debuff, status, movement, summon. Rough share of each across the cast.
- Combos or chains: does one skill set another up?

**For Ashgrid:** queued skills chain; augments modify skills; Celerity fires at the start.

## 4. Damage and defence
- The shape of the damage formula in words (attack against defence? a ratio? a difference?), with any random spread.
- Elements: how many, the weakness chart, the multipliers.
- Critical hits, guarding, evasion, resistances.
- How long a typical fight lasts (rounds), and how long a typical unit survives under focus.

**For Ashgrid:** four elements (water > fire > wind > earth > water) at ×1.5; reference fights end in round 8.

## 5. Statuses and positioning effects
- Each status: what it does, how long, how it's cured.
- Knockback, pulling, swapping places, tiles with effects.

## 6. Pacing and feel
- Battle camera, cut-ins, how long an action's animation runs, what can be skipped or sped up.
- What the player sees before committing (previews, forecasts, enemy intentions).
- Rewards after a fight and how they're presented.

**For Ashgrid:** forecast bar, Danger toggle (foe intents), cut-ins on first use, hit-stop and shake.

## 7. Enemies and AI
- How foes choose targets and skills; any scripted patterns or bosses with phases.
- How enemy groups are built (mixed elements, front/back roles).

## 8. What to take
A short ranked list, filled in last: the three to five ideas most worth adapting, and one thing EA does that we
should deliberately avoid.
