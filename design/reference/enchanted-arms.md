# Enchanted Arms — reference notes

What we learn from studying Enchanted Arms (2006): how its battles flow and why they feel the way they do, written in
our own words. This file is for understanding, not copying: no decompiled code, no verbatim data tables, skill names
or dialogue go into Ashgrid. We read how a mechanic works, note why it works, then design our own version.

Filled in from the EnchantedArms Ghidra project: its reverse-engineering notes, the data files and the in-game help.
Each section ends with **For Ashgrid**: what we might take, change or avoid. Anything uncertain is marked
*(unconfirmed)*. Much of what comes from data files was read but not watched in play, and the shapes below are
described, not quoted: no formulas or tuning values.

## 1. A turn, start to finish
- A turn covers all allies and all enemies. Each unit gets one move and one action.
- The player gives every ally their move and action, then confirms, and the turn plays out.
- Instructions can be changed any time before confirming.
- A knocked-out unit stays on the grid for three turns and can be revived. After that it leaves the battle.
- Between turns, Vitality falls by one for each unit and the combo gauges rise.
- Whether Agility orders actions inside a turn is *(unconfirmed)*. The help only ties Agility to surprise attacks and to
  the cost of fleeing.
- Fleeing always works but costs Vitality.

**For Ashgrid:** the plan-then-resolve shape already matches ours. Our queue gives the player the order as a tool, and
EA doesn't clearly do that, so ours is the stronger choice here. Take the idea of a small cost for every turn spent,
not the plan structure.

## 2. The grid and aiming
- Each side has its own 4×3 grid, 24 squares in all. Units stay on their side.
- Units occupy 1, 4 or 12 squares, so a large foe fills much of its side and changes what shapes can reach.
- Almost all units move the same short distance, and a rare exception reads as a real trait.
- Range is drawn in red squares before committing. Everything inside takes the hit, so targeting is about shape.
- Shapes come from a small shared library of grid patterns *(unconfirmed)*. Skill text speaks of a single enemy, a
  rank, a column, a wide area and all enemies.
- **Cover:** a unit with another unit in front of it takes less from close attacks. Ranged attacks ignore this. Cover
  works for both sides, and one tutorial has the player prove it by hitting two identical golems.

**For Ashgrid:** Cover is the idea to test. Reach already says who melee can touch; Cover would add how much a blocked
target suffers, so a thin front line still matters without being a hard wall.

## 3. Skills
- A unit equips up to five skills and five supports. EX skills are separate and need no equipping.
- Skills are learned with SP from a family pool. Items unlock more of the pool, so exploring feeds builds.
- Costs are EP only, with no cooldowns. Standing by recovers EP. Items use no EP, which keeps a dry unit useful.
- The cast's skills lean heavily to damage: close first, then ranged, then a large group the game files under "cover"
  skills, which hold recovery, positioning tricks and attacks alike. Dedicated support and EX are smaller groups.
- Effects seen in skill text: poison, HP barriers and skills that strip them, knockback, HP or EP drain, revive, seal,
  counter. Drain, barriers and poison are the common ones.
- **Combo attacks:** when a unit's combo gauge is full, two or more units hitting the same foe join up, and damage
  climbs with each extra member. Bonds raise how full the gauge starts.
- **EX:** a party-wide gauge pays for huge skills. It carries between battles, so saving it is a real decision.

**For Ashgrid:** our chains come from queue order, which is more deliberate than a gauge that fires when full. Consider
bond-driven head starts on something we already have, instead of adding a new gauge. A shared meter that survives
between fights fits expedition runs well.

## 4. Damage and defence
- The damage formula itself is *(unconfirmed)*. Only the inputs are known: Direct and Ranged for attackers, plus
  Support, Agility, element and Cover.
- Six elements (earth, water, fire, wind, light, dark) plus non-elemental. Opposing elements hit harder and matching
  elements hit much softer. Fire against water is confirmed. Earth/wind and light/dark are likely pairs
  *(unconfirmed)*.
- **Overbreak:** dealing more than a foe's max HP in one turn earns extra SP, and twice that is a higher tier. Foes can
  do it to you, and it costs Vitality.
- Critical hits, evasion and guarding *(unconfirmed)*. Barriers act as a form of guard.
- Fight length *(unconfirmed)*.
- A foe at the same level as a party member is stronger than that member, but shares the same element and growth.

**For Ashgrid:** the same-element penalty is an extra teaching tool our four-element wheel doesn't need. Overbreak is
worth taking: it makes overkill a goal and gives a clear reason to celebrate a big hit, which suits our hit-stop.

## 5. Statuses and positioning effects
- Poison, seal, stun and barriers appear in skill text. Exact rules, durations and cures *(unconfirmed)*.
- Knockback moves targets, sometimes a whole rank. Barriers can be stripped by specific skills.
- No tiles with effects found *(unconfirmed)*.

## 6. Pacing and feel
- **Vitality** is EA's signature. It sits beside HP but stays lost after a fight. It falls per turn, when attacked, when
  a unit stays down, when hit by the top Overbreak tier, and when fleeing. At zero a unit is out until repaired.
  Recharge stations restore it, and benched units recover slowly unless they hit zero.
- HP and EP refill after every fight, so a win is rarely a slog, and Vitality does the carrying.
- EX can be boosted during its animation by shaking the controller, which keeps the player involved in a long move.
- The result screen keeps each unit's before-fight values, so gains can animate from old to new.
- The learn screen simulates the unit with the new skill and shows the stat change before paying.
- Dancing in the field fills the EX gauge but brings more encounters, a small trade the player opts into.
- Camera, cut-ins and skip options *(unconfirmed)*. Not studied.

**For Ashgrid:** our expedition already carries health between fights and keeps knocked-out heroes down for the run, so
Vitality's job is mostly done. Don't add it as a second bar. Take its lesson instead: a small cost per turn rewards fast
wins. Before/after numbers on our result screen and a preview before spending are both cheap wins.

## 7. Enemies and AI
- Each unit has its own table of weights across kinds of action: direct attack, special attack, status attack, heal,
  cure, buff, waiting, moving to shield, moving to hide, and each of its skills. Each turn seems to be a weighted pick
  *(unconfirmed)*.
- So enemy personality is data. Tilting a few weights makes an aggressive, cautious or support unit without new code.
- Bosses raise the weight of signature skills, and the same character can have different tables per story fight.
- Enemy groups are defined as parties with waves, and a fight can continue past the first group.
- Foes telegraph nothing through a preview that we found *(unconfirmed)*.

**For Ashgrid:** we show foe intents with Danger, so weighted picks should be rolled before the plan phase and then
shown. That keeps EA's cheap variety while staying honest with the player.

## 8. What to take
1. **Overbreak tiers.** Overkill becomes a goal, and our battle feel is ready to sell it.
2. **Cover.** One small rule that gives more meaning to front and back.
3. **A shared gauge that survives between fights.** Natural on an expedition, and it builds tension across a run.
4. **Self-correcting growth.** Each stat tracks an expected line for that unit: a level-up has some randomness, but a
   stat that falls behind gains more. Nobody's favourite hero gets ruined by bad rolls.
5. **Per-unit action weights.** Cheap enemy personality that keeps working as the roster grows.

**Avoid:** locking half the roster out of growth. EA's golems can't learn skills or raise stats, which leaves them
static. A collection game needs every hero to be worth investing in.
