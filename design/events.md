# Wayside events

**Status: approved as written and built on 2026-11-02, including the replacement of Cache and Trial, the event that brings back a
fallen hero, and the name. The live events are `game/core/events.gd`: 33 so far, three per road and six shared.**

Short, flavoured random events on the road, like the occurrences in Honkai: Star Rail's Simulated Universe: you step
onto an unknown stop, read a small scene, make a choice, and live with what happens. The scenes and text below are our
own. Only the idea of the format is borrowed.

## The short version

- Add one new stop, the **Wayside**, shown on the map as an unknown stop. You don't know what's there until you arrive.
- It **replaces Cache and Trial**. Both are thin today, and both fit inside an event: a cache is an event with a find,
  and a trial is an event with a roll.
- Each event is a scene of two or three sentences, then two or three choices, then a one-line outcome.
- Each road has its own events, and some shared ones can turn up anywhere.
- Outcomes use what the run already has: embers, health, boons, picks, rerolls, augments and fights.

## New stop, or inside the old ones?

What the three stops do today:

| Stop | What you decide | Why it falls short |
|---|---|---|
| Boon | Which of three blessings | Works well. It is a clean build choice, so leave it alone. |
| Cache | Nothing: it opens and pays | One line ("Something left on the road"), then a reward. |
| Trial | Which hero rolls | One fixed test with a random aptitude and no story. Failing costs nothing. |

**Recommendation: a new stop that absorbs Cache and Trial.** Putting events inside the existing stops would break what
the map promises. A stop labelled Cache should be a cache, and the surprise is half of why occurrences are fun. The
unknown stop also makes a new kind of map choice: the fight you can plan for, or the stop you can't.

Keeping Cache and Trial beside a new stop would leave three kinds of small reward stop, and the two plain ones would
feel worse next to it.

## How it sits on the map

| Stop | Weight now | Proposed |
|---|---|---|
| Skirmish | 40 | 34 |
| Elite | 12 | 12 |
| Camp | 11 | 11 |
| Boon | 15 | 15 |
| Cache | 11 | gone |
| Trial | 11 | gone |
| Wayside | | 28 |

That is about one Wayside on a Basalt walk and about two on a Saltglass walk, more if you steer towards them. Fights
drop a little so that events can be frequent. It can appear from the second layer on, as Cache and Trial do now. These
numbers are first guesses.

## The shape of an event

```
key        unstair
road       basalt (or "any" for the shared pool)
title      the unfinished stair
scene      two or three sentences
choices    two or three, the last always a safe way out
```

Each choice has a label, an optional condition, and an outcome:

| Choice type | How it resolves |
|---|---|
| Plain | Happens as written. |
| Cost | Pay first, embers or health. Greyed out if you can't afford it. |
| Roll | You pick a hero, who rolls d20 on the named aptitude against 12, +3 if favored: 45%, or 60% favored. Same as today's Trial. |
| Hero | Appears only with the right hero standing in the squad, and needs no roll. |

**Outcomes:** gain or lose embers, heal the squad, hurt a hero, a boon, an augment, a free reroll, or a fight.

**Fair-play rules** (each one gets a check):

1. Every event has a safe choice. The last choice always costs nothing.
2. Costs are shown. The size of a prize can stay a mystery, but never what you will pay.
3. An event never knocks out a hero or ends a run. Health loss stops at 1 health. Only a fight can do that.
4. A failed roll hurts only the hero who rolled, so a bad result is never a surprise for the whole squad.
5. Rewards scale like everything else: embers are shares of a `wayside` purse (45 at danger 1, the same as a trial,
   scaled by danger and Tithe), and the stop's rarity sets boon rarity and how big a find is.
6. No event repeats within a run. Events are drawn from the run's seed, like boon offers.
7. A fight from an event is a normal fight, so it pays out and offers a hero pick as usual.

## Fitting each road

Each road draws about two thirds of its events from its own pool, and the rest from the shared pool. The cast comes
from the unplayed archetypes in `Lore`, so the player meets the world's people before they ever become heroes.

| Road | Mood | Who you meet | Leans towards |
|---|---|---|---|
| The Basalt Steps | Duty that outlived its reason | Golems at their work, skalds, hot springs | Defense, health, might and resolve |
| The Aqueduct | Soft, watchful, a bit unreal | Lamp-keepers, perfumers, shrines under water | Healing, speed, charm and lore |
| The Saltglass Road | Old fire, cost and temptation | Mirror-makers, star-reckoners, the caravan that ran | Attack, embers, high stakes |
| The Standing Stones | Old rules nobody explains | Herders, kite-tiers, stone-keepers | Speed, wits and resolve |
| The Empty Pavilions | A party that ended badly | What stayed behind, lantern-menders | Attack, charm, risky deals |
| The Walking Wood | Lost and watched | Path-readers, moss shrines, the trees | Dodging, finesse and healing |
| The Serpent Archive | Knowledge at a price | Scroll-keepers, river monks | Lore, embers and upgrades |
| The Veiled Undercroft | Secrets for sale | Silk brokers, smugglers, ember-keepers | Charm, embers, risky deals |
| The Whale Cathedral | Awe and old grief | Pilgrims, bell-ringers, ice-cutters | Healing, resolve and lore |
| Shared | Strangers on any road | Spice merchants, hedge healers, quipu keepers, griots | Trades and odd deals |

Heroes on their home road get extra lines and hero choices: Basalt on the Steps, Varuni at the Palace, Surya and the
Seer on the Saltglass.

The Aqueduct (`lotus`) lies below the Lotus Palace in Jaladesh, so the lamp samples fit it. The game now has nine roads;
this page covers three, and each of the others needs its own pool when this is built. Player text now says gold where
this page says embers.

## Eight sample events

Numbers are first guesses at danger 1. "Purse" is the 45-ember Wayside purse.

### The Basalt Steps

**The unfinished stair**

> A golem sets a step, lifts it out, and sets it again. Nobody has told it the stair is finished. Nobody is left to.

- *Take the other end.* Might roll. Success: a Bulwark boon. "It sets the stone once." Failure: the hero loses 15%
  health.
- *Tell it the work is done.* Charm roll. Success: 2 purses. "It looks at its hands, then gives you its wages."
  Failure: a skirmish. "It disagrees."
- *Basalt lifts it alone.* (Basalt standing.) A Bulwark boon, one rarity better. "Neither of them says anything."
- *Walk on.* "Behind you: set, lift, set."

**The warm water**

> A skald sits in a hot spring up to her chin. She offers praise at a fair price, and mockery for free.

- *Pay for a verse.* Costs 1 purse. A Whetstone boon. "You had no idea you were this brave."
- *Correct her metre.* Wits roll. Success: a Whetstone boon, free. "She laughs until the water moves." Failure: the
  hero loses 10% health. "That one will follow you home."
- *Just get in.* The squad heals 15%. She doesn't look up.

### The Aqueduct

**A lamp going upstream**

> One lotus lamp is moving against the water. It stops in front of you, and waits to be given a name.

- *Give it the name of someone fallen.* (A hero has fallen.) Costs half your embers. That hero stands at 30% health.
  The lamp goes on without you.
- *Light yours from it.* The squad heals 15%.
- *Let it pass.* It goes on without you. It knows the way.

**Rain on clay**

> There's a perfumer's stall here, with no dry ground for it to stand on. She holds out a stoppered vial. "You've
> already said yes. I can smell it."

- *Pay her.* Costs 1 purse. A Fleetfoot boon.
- *Say no, and mean it.* Resolve roll. Success: a Fleetfoot boon, free. "She bows, slightly annoyed." Failure: you lose
  2 purses. "You're holding the vial. You've paid. You feel fine about it."
- *Breathe through your mouth, and leave.*

### The Saltglass Road

**The one who turned back**

> The footprints in the glass all run the same way. One set stops, turns, and walks back towards the fire.

- *Follow the many.* 1 purse, picked from what they dropped.
- *Follow the one.* Finesse roll. Success: 3 purses and an augment. Failure: the hero loses 20% health. "The glass is
  still hot, this far in."
- *The Seer stands in the print.* (Seer standing.) 3 purses and an augment. "It fits. She doesn't explain."
- *Keep to the road.*

**A hall of small mirrors**

> A wall of mirror shards stands alone in the dunes. All of you are in it. One of the reflections has stopped moving.

- *Bow to it.* Lore roll. Success: a Kinfire boon. Failure: the hero loses 10% health. "It doesn't bow back."
- *Break the glass.* An elite fight. The foes are your reflection's idea.
- *Look away.* "It's still looking when you leave."

### Shared

**The knotted cord**

> A woman with a bundle of cords offers you embers, at no charge today. She ties a knot, to remember.

- *Take the loan.* 3 purses now. 5 purses come out of what you bank at the end of the run.
- *Ask what you already owe.* Lore roll. Success: 2 free rerolls. "One of your knots was hers." Failure: nothing. "She
  says you'd rather not know."
- *Keep your hands in your pockets.*

**Two mushrooms**

> A hedge healer keeps the one that mends and the one that kills in the same pocket. She says it keeps her honest.

- *Take one.* No roll, even odds. The squad heals 30%, or every hero loses 10%.
- *Tell them apart.* Lore roll. Success: the squad heals 30%. Failure: the hero loses 10% health.
- *Say you've eaten.*

## What it would take

All of this is to be built after approval.

- **Rules:** a `wayside` node with its weights, `PURSE.wayside`, and the event data in a new `game/core/events.gd`.
  Cache and Trial come out, and `design/expedition.md` is updated.
- **New run state:** only the used-event list and a debt for the loan. Removing the loan removes the debt.
- **Screen:** built on the existing `_event` panel, with ember buttons for the choices and studs "go on" after the
  outcome, so one stud per screen still holds. A hero's `Bust` speaks on hero choices. It needs a `node_wayside` glyph
  and `#event-wayside` for playtest links.
- **Checks:** the fair-play rules above, and every event's aptitudes, heroes and boons exist. The reference fights are
  untouched, since none of this enters combat.
- **Content:** a first release of about 8 events per road plus 8 shared, so about 32. The samples above are 8 of them.
- **Music:** one new `wayside` slot for the road music session. The `cache` and `trial` slots go away.
- **Later, not now:** scene art for each event, and events that remember earlier ones, such as the warden mentioning
  the lamp you let pass.

## Decisions for you

1. **Replace Cache and Trial?** Recommended. The alternative is to keep both and add the Wayside at a lower weight.
2. **Can an event bring back the fallen?** "A lamp going upstream" does this for a heavy price. It answers one of the
   open questions in `design/expedition.md`, but only by luck of the draw. Recommended, as long as it stays rare.
3. **The name.** "Wayside" is the working name.
