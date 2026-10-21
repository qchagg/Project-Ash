class_name Battle
extends RefCounted
## The combat engine, ported from the sandbox's battle section; the checks in tests/run_checks.gd replay its two
## reference fights round for round. Each side has its own grid (row 0 is the front). Rounds are planned, then resolved:
## the queue fires in order (each skill in an unbroken run adds to the next damaging skill), unqueued heroes basic
## attack by speed, enemies act by speed, then burns tick and cooldowns fall.
##
## The engine resolves instantly. What happened is recorded in `events` for a screen to play back: "flash" and
## "float" on a tile, "log" lines, and "step" between beats. Logs are plain text.

## Grid size per side. 4×4 is the working default; 3×3 is the v0.1 layout the baseline fight was recorded on.
const GRID_SIZES := [Vector2i(4, 4), Vector2i(3, 4), Vector2i(3, 3)]
const PNAME := {"single": "Single", "pierce": "Lane", "sweep": "Row", "cross": "Cross", "all": "Full grid"}
const DEFAULT_SQUAD := ["kaede", "brann", "sorrel", "ilse"]

const FOES := [
	{"key": "golem", "name": "Basalt Golem", "short": "Golem", "elem": "earth", "legacy_elem": "fire", "range": "melee",
		"max_hp": 1500, "atk": 115, "def": 85, "spd": 60, "r": 0, "c": 1,
		"portrait": {"src": "res://art/portraits/golem.webp", "eyes": [57, 37], "chin": 55}, "skills": [
		{"name": "Magma Fist", "kind": "dmg", "range": "melee", "pattern": "single", "power": 1.5, "cd": 3, "fx": {"burn": 2}},
		{"name": "Quake", "kind": "dmg", "range": "melee", "pattern": "sweep", "power": 0.8, "cd": 3}]},
	{"key": "blade", "name": "Galeblade", "short": "Galeblade", "elem": "wind", "range": "melee",
		"max_hp": 950, "atk": 145, "def": 40, "spd": 110, "r": 0, "c": 0,
		"portrait": {"src": "res://art/portraits/blade.webp", "eyes": [38, 41], "chin": 58}, "skills": [
		{"name": "Gust Step", "kind": "dmg", "range": "melee", "pattern": "single", "power": 1.6, "cd": 4, "fx": {"stun": 1}},
		{"name": "Cyclone Cut", "kind": "dmg", "range": "melee", "pattern": "sweep", "power": 1.0, "cd": 2}]},
	{"key": "caller", "name": "Tidecaller", "short": "Tidecaller", "elem": "water", "range": "ranged",
		"max_hp": 900, "atk": 125, "def": 45, "spd": 85, "r": 1, "c": 2,
		"portrait": {"src": "res://art/portraits/caller.webp", "eyes": [42, 44], "chin": 60}, "skills": [
		{"name": "Mend", "kind": "heal", "pattern": "all", "power": 1.2, "cd": 4},
		{"name": "Tidal Pillar", "kind": "dmg", "range": "ranged", "pattern": "pierce", "power": 1.15, "cd": 3}]},
	{"key": "seer", "name": "Ashen Seer", "short": "Seer", "elem": "fire", "range": "ranged",
		"max_hp": 800, "atk": 135, "def": 35, "spd": 95, "r": 2, "c": 1,
		"portrait": {"src": "res://art/portraits/seer.webp", "eyes": [33, 40], "chin": 61}, "skills": [
		{"name": "Ember Rain", "kind": "dmg", "range": "ranged", "pattern": "all", "power": 0.55, "cd": 4, "fx": {"burn": 1}},
		{"name": "Flare", "kind": "dmg", "range": "ranged", "pattern": "single", "power": 1.6, "cd": 2}]},
]
## Enemy starting tiles per grid size ("colsxrows"); a size not listed uses each foe's own r, c (the v0.1 layout).
const FOE_START := {"4x4": {"golem": Vector2i(0, 1), "blade": Vector2i(0, 2), "caller": Vector2i(2, 0), "seer": Vector2i(3, 3)}}

## v0.2 rule proposals plus Reach. All start off, so the reference fights hold; a screen switches on what it plays with.
const RULE_DEFS := {
	"sightline": {"name": "Sightline", "per_row": 0.05, "desc": "Ranged falloff also counts the attacker's depth: −5% for each row it stands behind its own front row."},
	"screening": {"name": "Screening", "per_unit": 0.25, "floor": 0.5, "desc": "Lane attacks lose 25% for each unit already hit in that lane, down to 50%."},
	"kindred": {"name": "Kindred", "mult": 0.85, "desc": "Hitting a target of your own element deals ×0.85."},
	"focus": {"name": "Focus", "per_link": 0.05, "desc": "A chain link that hits the same target as the previous link gets +5% more per focused link."},
	"shatter": {"name": "Shatter", "overshoot": 0.5, "desc": "A killing blow that overshoots by 50% of max HP shatters the target: counted for rewards, and it can never be revived."},
	"last_stand": {"name": "Last Stand", "rounds": 2, "revive_hp": 0.25, "desc": "A hero at 0 HP stays downed for 2 rounds. A heal that covers their tile revives them at 25% HP; otherwise they fall for the run."},
	"ashfall": {"name": "Ashfall", "from": 8, "desc": "From round 8, every unit takes the Burn tick each round. A unit already Burning ticks once, not twice; cleansing can't stop it."},
	"ground": {"name": "Ground", "desc": "A ranged area skill (cross, row or lane) can be aimed at any enemy tile, empty or not, to catch the units its shape covers. It stays on that tile even if the unit beside it falls first."},
	"reach": {"name": "Reach", "desc": "Single-target melee only reaches the front-most enemy in the attacker's own lane, and only from the front row. Move to line up a hit."},
}

## Tuning: element edge, chain step per link, ranged falloff per row.
var tune := {"elem": 1.5, "chain": 0.10, "fall": 0.10, "step": 2}
var elem_mode := "four"
var rows := 4
var cols := 4
## Area shapes grow with the grid (a lane gains the next lane, a row the next row, a cross reaches 2) when a side is longer than 3.
var scaled := true
var rules := {}

var round_num := 1
## "form" (placing heroes), "plan" (queueing), "run" (resolving), "over".
var phase := "plan"
var units: Array = []
var queue: Array = []
## Planned steps, by hero id (Vector2i). Like Enchanted Arms, a hero can step and act in the same round: while planning,
## the step and the action are both set; when the round resolves, each hero steps and then acts, in queue order.
## A hero with a step but no queued action steps before their basic attack.
var steps := {}
var buffs: Array = []
var tiles: Array = []
var trace: Array = []
var result := ""
var dealt := 0
var taken := 0
var shatters := {"P": 0, "E": 0}
var events: Array = []
var _fx_seq := 0


func _init() -> void:
	for k in RULE_DEFS:
		rules[k] = false


func rule(k: String) -> Dictionary:
	return RULE_DEFS[k] if rules.get(k, false) else {}


# ---------- units ----------

## A unit from a hero or foe definition. Triangle mode turns Earth units back into their legacy element.
func mk(d: Dictionary, side: String) -> Dictionary:
	var u := d.duplicate(true)
	if elem_mode == "triangle" and d.has("legacy_elem"):
		u.elem = d.legacy_elem
	u.side = side
	u.id = side + "-" + d.key
	u.hp = d.max_hp
	u.cd = []
	for s in d.skills:
		u.cd.append(0.0)
	u.st = {"stun": 0, "burn": 0, "shield": 0, "guard": false}
	u.alive = true
	u.stacks = {}
	for k in d.get("stacks", {}):
		var s: Dictionary = d.stacks[k].duplicate(true)
		s.n = 0
		u.stacks[k] = s
	u.marks = []
	u.rf = {"moved": false, "damaged": false}
	u.downed = 0
	return u


## A unit for one of the player's cards: its rolled stats, stars and augmented skills.
static func card_unit(col: Collection, uid: String, b: Battle) -> Dictionary:
	var c := col.by(uid)
	var h := Data.hero(c.hero).duplicate(true)
	h.key = uid
	h.merge(col.stats(c), true)
	h.stars = c.stars
	h.augs = c.augs.map(func(a): return a.aug)
	h.skills = col.skills(c)
	return b.mk(h, "P")


## Sets up a fight: heroes in order, foes from FOES. `pos` places heroes by key (Vector2i row, col); unplaced
## heroes keep their own spot; a clash or an out-of-bounds tile moves to the first free tile.
func start(heroes: Array, pos := {}) -> void:
	var foes := FOES.map(func(d): return mk(d, "E"))
	place(heroes, pos)
	place(foes, FOE_START.get(grid_key(), {}))
	units = heroes + foes
	round_num = 1
	phase = "plan"
	queue = []
	steps = {}
	buffs = []
	tiles = []
	trace = []
	result = ""
	dealt = 0
	taken = 0
	shatters = {"P": 0, "E": 0}
	events = []


## The four starter heroes straight from their definitions, so the reference fights ignore the collection.
func pristine_heroes() -> Array:
	var out := []
	for h in Data.HEROES:
		if h.key in DEFAULT_SQUAD:
			out.append(mk(h, "P"))
	return out


func grid_key() -> String:
	return "%dx%d" % [cols, rows]


func place(us: Array, pos: Dictionary) -> void:
	var taken_tiles := {}
	for u in us:
		var p: Variant = pos.get(u.key)
		var t := Vector2i(u.r, u.c)
		if p != null and in_b(p.x, p.y):
			t = p
		if not in_b(t.x, t.y) or taken_tiles.has(t):
			for a in all_tiles():
				if not taken_tiles.has(a):
					t = a
					break
		u.r = t.x
		u.c = t.y
		taken_tiles[t] = true


## Formation: moves a hero to a tile on its grid, swapping with a hero already there.
func place_hero(id: String, r: int, c: int) -> void:
	var u := unit(id)
	if u.is_empty() or u.side != "P" or not in_b(r, c):
		return
	var other := at("P", r, c)
	if not other.is_empty() and other != u:
		other.r = u.r
		other.c = u.c
	u.r = r
	u.c = c
	_flash("P", r, c)


## Where each hero stands, by key, to carry into the next fight.
func formation() -> Dictionary:
	var out := {}
	for u in units:
		if u.side == "P":
			out[u.key] = Vector2i(u.r, u.c)
	return out


# ---------- the board ----------

static func opp(s: String) -> String:
	return "E" if s == "P" else "P"


func in_b(r: int, c: int) -> bool:
	return r >= 0 and r < rows and c >= 0 and c < cols


func at(side: String, r: int, c: int) -> Dictionary:
	for u in units:
		if u.alive and u.side == side and u.r == r and u.c == c:
			return u
	return {}


func dead_at(side: String, r: int, c: int) -> Dictionary:
	for u in units:
		if not u.alive and u.side == side and u.r == r and u.c == c:
			return u
	return {}


func downed_at(side: String, r: int, c: int) -> Dictionary:
	for u in units:
		if not u.alive and u.downed > 0 and u.side == side and u.r == r and u.c == c:
			return u
	return {}


func living(side: String) -> Array:
	return units.filter(func(u): return u.alive and u.side == side)


func unit(id: String) -> Dictionary:
	for u in units:
		if u.id == id:
			return u
	return {}


func all_tiles() -> Array:
	var t := []
	for i in rows:
		for j in cols:
			t.append(Vector2i(i, j))
	return t


func exposed(side: String, r: int, c: int) -> bool:
	for k in r:
		if not at(side, k, c).is_empty():
			return false
	return true


func elem_mult(a: String, b: String) -> float:
	if Data.beats(elem_mode, a, b):
		return tune.elem
	if Data.beats(elem_mode, b, a):
		return 1.0 / tune.elem
	return 1.0


static func name_of(u: Dictionary) -> String:
	return u.get("short", u.name)


func lane(r: int, c: int) -> String:
	var names := ["Front", "Mid", "Deep", "Back"] if rows == 4 else ["Front", "Mid", "Back"]
	return "ABCD"[c] + "·" + names[r]


# ---------- team buffs, stacks and marks ----------

## While planning, a buff already in the queue counts, so targeting matches what will happen when the queue resolves.
func team_flag(side: String, flag: String) -> bool:
	for b in buffs:
		if b.side == side and b.flags.get(flag, false):
			return true
	if phase != "plan":
		return false
	for q in queue:
		var u := unit(q.id)
		if u.is_empty() or u.side != side:
			continue
		var a := act(u, q.key)
		if a.has("team_buff") and a.team_buff.flags.get(flag, false):
			return true
	return false


func _clear_stacks(u: Dictionary, reason: String) -> void:
	for s in u.stacks.values():
		if reason in s.clear_on:
			s.n = 0


func _gain_stacks(u: Dictionary) -> void:
	for s in u.stacks.values():
		if s.gain == "still_unhit" and not u.rf.moved and not u.rf.damaged:
			s.n = mini(s.max, s.n + 1)


func _stack_bonus(u: Dictionary) -> float:
	var m := 1.0
	for s in u.stacks.values():
		m *= 1 + s.per_stack * s.n
	return m


static func _mark_applies(m: Dictionary, a: Dictionary) -> bool:
	return not m.has("only") or m.only == a.key


func _mark_bonus(u: Dictionary, a: Dictionary) -> float:
	var x := 1.0
	for m in u.marks:
		if _mark_applies(m, a):
			x *= 1 + m.dmg_bonus
	return x


func _on_damaged(u: Dictionary) -> void:
	u.rf.damaged = true
	_clear_stacks(u, "damaged")


# ---------- shapes ----------

func wide_lanes() -> bool:
	return scaled and cols > 3


func deep_rows() -> bool:
	return scaled and rows > 3


func cross_reach() -> int:
	return 2 if scaled and (rows > 3 or cols > 3) else 1


static func _partner(i: int, n: int) -> int:
	return i + 1 if i + 1 < n else i - 1


func shape_name(p: String) -> String:
	if p == "pierce" and wide_lanes(): return "2 lanes"
	if p == "sweep" and deep_rows(): return "2 rows"
	if p == "cross" and cross_reach() > 1: return "Wide cross"
	return PNAME.get(p, p)


func pattern(p: String, r: int, c: int) -> Array:
	var t := []
	match p:
		"single":
			t = [Vector2i(r, c)]
		"pierce":
			for cc in ([c, _partner(c, cols)] if wide_lanes() else [c]):
				for i in rows:
					t.append(Vector2i(i, cc))
		"sweep":
			for rr in ([r, _partner(r, rows)] if deep_rows() else [r]):
				for j in cols:
					t.append(Vector2i(rr, j))
		"cross":
			t = [Vector2i(r, c)]
			for d in range(1, cross_reach() + 1):
				t.append_array([Vector2i(r - d, c), Vector2i(r + d, c), Vector2i(r, c - d), Vector2i(r, c + d)])
		_:
			t = all_tiles()
	return t.filter(func(v): return in_b(v.x, v.y))


func area_of(a: Dictionary, r: int, c: int) -> Array:
	if a.kind == "move":
		return [Vector2i(r, c)]
	if a.kind == "tile":
		var t := [Vector2i(r, c), Vector2i(r + 1, c)] if a.get("wide", false) else [Vector2i(r, c)]
		return t.filter(func(v): return in_b(v.x, v.y))
	return pattern(a.pattern, r, c)


# ---------- actions and targets ----------

## An action by key: "s0", "s1"… for skills, or "basic", "move", "guard".
func act(u: Dictionary, key: String) -> Dictionary:
	if key == "basic":
		var a := {"name": "Strike" if u.range == "melee" else "Bolt", "kind": "dmg", "range": u.range, "pattern": "single",
			"power": 1.0, "cd": 0, "desc": "Basic attack on one target. Breaks the chain."}
		a.merge(u.get("basic", {}), true)
		a.key = key
		a.is_skill = false
		return a
	if key == "move":
		return {"key": key, "name": "Reposition", "kind": "move", "is_skill": false, "desc": "Step to an adjacent empty tile. Uses this hero’s turn."}
	if key == "guard":
		return {"key": key, "name": "Guard", "kind": "guard", "is_skill": false, "desc": "Take half damage until the round ends."}
	var i := key.substr(1).to_int()
	var s: Dictionary = u.skills[i].duplicate(true)
	s.key = key
	s.is_skill = true
	s.idx = i
	s.range = s.get("range", "ranged")
	return s


## Skills add a chain link, other actions break it, and anything flagged breaks_chain: false passes through untouched.
static func next_chain(chain: int, a: Dictionary) -> int:
	if a.get("breaks_chain", true) == false:
		return chain
	return chain + 1 if a.is_skill else 0


## Reach: single-target melee needs the attacker in its front row, and only the front-most enemy in its lane.
func reach_blocked(u: Dictionary, a: Dictionary) -> bool:
	return rules.get("reach", false) and a.kind == "dmg" and a.range == "melee" and a.pattern == "single" \
		and not team_flag(u.side, "melee_reach_all")


func targets(u: Dictionary, a: Dictionary) -> Dictionary:
	if a.kind == "move":
		var cand := all_tiles() if a.get("reach") == "any" else \
			[Vector2i(u.r - 1, u.c), Vector2i(u.r + 1, u.c), Vector2i(u.r, u.c - 1), Vector2i(u.r, u.c + 1)]
		return {"side": u.side, "tiles": cand.filter(func(v): return in_b(v.x, v.y) and at(u.side, v.x, v.y).is_empty() and downed_at(u.side, v.x, v.y).is_empty())}
	if a.kind == "tile":
		return {"side": opp(u.side), "tiles": all_tiles()}
	var side: String = opp(u.side) if a.kind == "dmg" or a.kind == "buff" else u.side
	var us := living(side)
	if a.kind == "dmg" and a.range == "melee" and not team_flag(u.side, "melee_reach_all"):
		us = us.filter(func(t): return exposed(side, t.r, t.c))
	if reach_blocked(u, a):
		us = us.filter(func(t): return u.r == 0 and t.c == u.c)
	return {"side": side, "tiles": us.map(func(t): return Vector2i(t.r, t.c))}


## Ground: a ranged area skill whose shape is worth placing (a cross, a row, a lane) can aim at any enemy tile.
func aims_ground(a: Dictionary) -> bool:
	return rules.get("ground", false) and a.kind == "dmg" and a.get("range", "ranged") == "ranged" \
		and a.get("pattern", "") in ["cross", "sweep", "pierce"]


## Where the player can aim an action: every enemy tile for a ground skill, otherwise the same tiles as `targets`.
## The AI keeps aiming at units through `targets` and `pick`.
func aim_tiles(u: Dictionary, a: Dictionary) -> Dictionary:
	if aims_ground(a):
		return {"side": opp(u.side), "tiles": all_tiles()}
	return targets(u, a)


## Why an action has nothing to aim at, for the screen to say; empty when it can be used.
func blocked_reason(u: Dictionary, a: Dictionary) -> String:
	if a.kind in ["guard"] or a.get("pattern", "") == "all":
		return ""
	if not targets(u, a).tiles.is_empty():
		return ""
	if reach_blocked(u, a):
		return "Move to the front of a lane with an enemy."
	return "Nothing in reach."


## The AI's preferred target for an action, or null.
func pick(u: Dictionary, a: Dictionary) -> Variant:
	var tg := targets(u, a)
	if tg.tiles.is_empty():
		return null
	if a.get("pattern", "") == "all":
		return Vector2i(1, 1)
	var best: Variant = null
	var bs := -1e9
	for v in tg.tiles:
		var t := at(tg.side, v.x, v.y)
		var s: float
		if a.kind == "dmg":
			var hits := pattern(a.pattern, v.x, v.y).filter(func(w): return not at(tg.side, w.x, w.y).is_empty()).size()
			s = hits * 1000 + (400 if elem_mult(u.elem, t.elem) > 1 else 0) - (float(t.hp) / t.max_hp) * 300
		else:
			s = -float(t.hp) / t.max_hp if not t.is_empty() else 0.0
		if s > bs:
			bs = s
			best = v
	return best


# ---------- events ----------

func _flash(side: String, r: int, c: int) -> void:
	events.append({"t": "flash", "side": side, "r": r, "c": c})


func _float(t: Dictionary, txt: String, cls: String) -> void:
	events.append({"t": "float", "side": t.side, "r": t.r, "c": t.c, "txt": txt, "cls": cls})


func _log(text: String, cls := "") -> void:
	events.append({"t": "log", "text": text, "cls": cls})


## A beat: carries the board as it stands, so a screen can show each beat rather than the end of the round.
func _step() -> void:
	events.append({"t": "step", "snap": snapshot()})


## Every unit's changing state, by id: {hp, r, c, alive, downed, st}.
func snapshot() -> Dictionary:
	var out := {}
	for u in units:
		out[u.id] = {"hp": u.hp, "r": u.r, "c": u.c, "alive": u.alive, "downed": u.downed, "st": u.st.duplicate()}
	return out


## Hands over what happened since the last call.
func take_events() -> Array:
	var e := events
	events = []
	return e


# ---------- resolving ----------

## A unit reaching 0 HP: Shatter can mark the kill; Last Stand leaves an unshattered hero downed instead of gone.
func _fall(t: Dictionary, overshoot: int, by: String) -> void:
	t.hp = 0
	t.alive = false
	var sh := rule("shatter")
	if not sh.is_empty() and by != "" and overshoot >= sh.overshoot * t.max_hp:
		t.shattered = true
		shatters[by] += 1
	var ls := rule("last_stand")
	if not ls.is_empty() and t.side == "P" and not t.get("shattered", false):
		t.downed = ls.rounds


func hurt(u: Dictionary, t: Dictionary, a: Dictionary, chain: float, bonus := 1.0, screen := 1.0) -> String:
	var elem: String = a.get("elem", u.elem)
	var em := elem_mult(elem, t.elem)
	var kin: float = RULE_DEFS.kindred.mult if rules.kindred and elem == t.elem else 1.0
	var flat: bool = a.get("ignores_falloff", false) or team_flag(u.side, "ignores_falloff")
	var sight: float = RULE_DEFS.sightline.per_row * u.r if rules.sightline else 0.0
	var depth: float = maxf(0.0, 1 - tune.fall * t.r - sight) if a.range == "ranged" and not flat else 1.0
	var raw: float = u.atk * a.power * em * chain * depth * (0.5 if t.st.guard else 1.0) * bonus * kin * screen
	var d := maxi(1, roundi(raw * 100 / (100 + t.def)))
	var absorbed: int = mini(t.st.shield, d)
	t.st.shield -= absorbed
	var got := d - absorbed
	var hp_before: int = t.hp
	t.hp -= got
	if got > 0:
		_on_damaged(t)
	if u.side == "P":
		dealt += got
	else:
		taken += got
	_float(t, "blocked" if got == 0 else "-%d" % got, "blocked" if got == 0 else "crit" if em > 1 else "resist" if em < 1 else "hurt")
	var fx: Dictionary = a.get("fx", {})
	if t.hp <= 0:
		_fall(t, got - hp_before, u.side)
	else:
		if fx.get("stun", 0):
			t.st.stun = maxi(t.st.stun, fx.stun)
		if fx.get("burn", 0):
			t.st.burn = maxi(t.st.burn, fx.burn)
	var note := "%s %d" % [name_of(t), got]
	if absorbed: note += " (%d shielded)" % absorbed
	if em > 1: note += " weak"
	if em < 1: note += " resists"
	if kin < 1: note += " kindred"
	if t.get("shattered", false): note += " SHATTERED"
	elif t.downed: note += " downed"
	elif not t.alive: note += " KO"
	elif fx.get("stun", 0): note += " stunned"
	elif fx.get("burn", 0) and not a.is_skill: note += " burning"
	return note


# Tile effects (a board layer separate from units): {kind, label, side, r, c, owner, rounds, triggers, once, payload}.
func effects_at(side: String, r: int, c: int) -> Array:
	return tiles.filter(func(e): return e.side == side and e.r == r and e.c == c)


func _trigger_tiles(trigger: String, u: Dictionary) -> bool:
	for e in effects_at(u.side, u.r, u.c).filter(func(x): return trigger in x.triggers):
		if not u.alive:
			break
		if e.get("once", false):
			tiles.erase(e)
		var src := unit(e.owner)
		var p: Dictionary = e.payload
		_flash(u.side, u.r, u.c)
		var note := name_of(u)
		if p.get("power", 0):
			note = hurt(src, u, {"name": e.name, "kind": "dmg", "range": "ranged", "pattern": "single", "power": p.power,
				"elem": p.elem, "fx": p.get("fx", {}), "ignores_falloff": true, "is_skill": false}, 1.0)
		_log("%s %s %s’s %s: %s" % [name_of(u), "steps onto" if trigger == "on_enter" else "sets off", name_of(src), e.name, note])
		_step()
	return u.alive


func move_unit(u: Dictionary, r: int, c: int, a: Dictionary) -> void:
	u.r = r
	u.c = c
	u.rf.moved = true
	if not a.get("keeps_stacks", false):
		_clear_stacks(u, "moved")
	_flash(u.side, r, c)
	_trigger_tiles("on_enter", u)


## Carries out one action. `links` is the chain length before it; `ctx` (queue only) carries the focus state.
func perform(u: Dictionary, a: Dictionary, r: int, c: int, links: int, ctx: Variant = null) -> void:
	var nm := name_of(u)
	if not _trigger_tiles("on_act", u):
		return
	# A hero's signature skill plays their cut-in before it lands.
	if a.get("is_skill", false) and a.get("cutin", false) and u.has("cutin"):
		events.append({"t": "cutin", "src": u.cutin, "id": u.id, "name": a.name})
	if a.kind == "guard":
		u.st.guard = true
		_flash(u.side, u.r, u.c)
		_log("%s raises a guard." % nm)
		_step()
		return
	if a.kind == "move":
		if Vector2i(r, c) in targets(u, a).tiles:
			_log("%s → %s: lands on %s%s" % [nm, a.name, lane(r, c), ", chain held" if a.get("breaks_chain", true) == false else ""] if a.is_skill else "%s moves to %s." % [nm, lane(r, c)])
			if a.is_skill:
				u.cd[a.idx] = float(a.cd)
			if a.has("mark"):
				var m: Dictionary = a.mark.duplicate(true)
				m.until = round_num + a.mark.rounds - 1
				u.marks.append(m)
			trace.append({"id": u.id, "key": a.key, "chain_mult": 1.0, "bonus": 1.0})
			move_unit(u, r, c, a)
		else:
			_log("%s can’t reach %s." % [nm, lane(r, c)])
		_step()
		return
	if a.kind == "tile":
		var side := opp(u.side)
		var area := area_of(a, r, c)
		_fx_seq += 1
		tiles = tiles.filter(func(e): return not (e.owner == u.id and e.kind == a.effect.kind))
		for v in area:
			var e: Dictionary = a.effect.duplicate(true)
			e.merge({"name": a.name, "group": _fx_seq, "side": side, "r": v.x, "c": v.y, "owner": u.id}, true)
			tiles.append(e)
			_flash(side, v.x, v.y)
		u.cd[a.idx] = float(a.cd)
		trace.append({"id": u.id, "key": a.key, "chain_mult": 1.0, "bonus": 1.0})
		_log("%s → %s: trap set on %s" % [nm, a.name, " and ".join(area.map(func(v): return lane(v.x, v.y)))])
		_step()
		return
	if a.kind == "buff":
		var b: Dictionary = a.team_buff
		buffs = buffs.filter(func(x): return not (x.side == u.side and x.name == b.name))
		buffs.append({"name": b.name, "side": u.side, "flags": b.flags.duplicate(), "until": round_num + b.rounds - 1})
		u.cd[a.idx] = float(a.cd)
		for t in living(opp(u.side)):
			_flash(t.side, t.r, t.c)
		trace.append({"id": u.id, "key": a.key, "chain_mult": 1.0, "bonus": 1.0})
		_log("%s → %s: enemy grid lit %s" % [nm, a.name, "through next round" if b.rounds > 1 else "until round end"])
		_step()
		return
	var side: String = opp(u.side) if a.kind == "dmg" else u.side
	if a.pattern != "all" and not Vector2i(r, c) in aim_tiles(u, a).tiles:
		var p: Variant = pick(u, a)
		if p == null:
			_log("%s’s %s has no target." % [nm, a.name])
			_step()
			return
		r = p.x
		c = p.y
	var hit := []
	for v in pattern(a.pattern, r, c):
		var t := at(side, v.x, v.y)
		if not t.is_empty():
			hit.append(t)
	var focused := 0
	if ctx != null and a.kind == "dmg" and a.is_skill:
		var primary := at(side, r, c)
		focused = ctx.n + 1 if not primary.is_empty() and ctx.prev == primary.id else 0
		ctx.prev = primary.id if not primary.is_empty() else ""
		ctx.n = focused
	var focus_add: float = RULE_DEFS.focus.per_link * focused if rules.focus else 0.0
	var chain_mult: float = 1 + tune.chain * links + focus_add if a.kind == "dmg" and a.is_skill else 1.0
	var bonus: float = _stack_bonus(u) * _mark_bonus(u, a) if a.kind == "dmg" and hit.size() else 1.0
	var sc := rule("screening") if a.kind == "dmg" and a.pattern == "pierce" else {}
	var revived := []
	if a.kind == "heal" and rules.last_stand:
		for v in pattern(a.pattern, r, c):
			var d := downed_at(side, v.x, v.y)
			if d.is_empty():
				continue
			d.alive = true
			d.downed = 0
			d.hp = maxi(1, roundi(d.max_hp * RULE_DEFS.last_stand.revive_hp))
			d.st = {"stun": 0, "burn": 0, "shield": 0, "guard": false}
			_float(d, "revived", "mend")
			_flash(side, d.r, d.c)
			revived.append(name_of(d))
	var notes := []
	for k in hit.size():
		var t: Dictionary = hit[k]
		_flash(side, t.r, t.c)
		if a.kind == "dmg":
			# Screening counts only the units already hit in this unit's own lane.
			var ahead := 0
			if not sc.is_empty():
				for j in k:
					if hit[j].c == t.c:
						ahead += 1
			notes.append(hurt(u, t, a, chain_mult, bonus, maxf(sc.floor, 1 - sc.per_unit * ahead) if not sc.is_empty() else 1.0))
		elif a.kind == "heal":
			var before: int = t.hp
			t.hp = mini(t.max_hp, t.hp + roundi(u.atk * a.power))
			if a.get("fx", {}).get("cleanse", false):
				t.st.burn = 0
			_float(t, "+%d" % (t.hp - before), "mend")
		elif a.kind == "shield":
			var amt := roundi(u.def * a.power)
			t.st.shield += amt
			_float(t, "+%d" % amt, "shield")
	if a.kind == "dmg" and hit.size():
		for s in u.stacks.values():
			s.n = 0
		u.marks = u.marks.filter(func(m): return not _mark_applies(m, a))
	if a.is_skill:
		u.cd[a.idx] = float(a.cd)
	trace.append({"id": u.id, "key": a.key, "chain_mult": chain_mult, "bonus": bonus, "focused": focused})
	var head := "%s → %s" % [nm, a.name]
	if chain_mult > 1: head += " (chain ×%.2f%s)" % [chain_mult, ", focus" if focus_add else ""]
	if bonus > 1: head += " (focus ×%.2f)" % bonus
	var tail := ""
	if a.kind == "dmg":
		tail = ", ".join(notes)
	elif a.kind == "heal":
		tail = "heals %d allies%s" % [hit.size(), ", revives " + ", ".join(revived) if revived.size() else ""]
	else:
		tail = "shields %d allies" % hit.size()
	_log("%s: %s" % [head, tail])
	_step()


func _stunned_skip(u: Dictionary) -> void:
	u.st.stun -= 1
	_flash(u.side, u.r, u.c)
	_float(u, "stunned", "stun")
	_log("%s is stunned and loses the turn." % name_of(u))
	_step()


func enemy_turn(u: Dictionary) -> void:
	if u.st.stun > 0:
		_stunned_skip(u)
		return
	var a := {}
	for i in u.skills.size():
		if u.cd[i] > 0:
			continue
		var s := act(u, "s%d" % i)
		if s.kind == "heal" and not living(u.side).any(func(t): return float(t.hp) / t.max_hp < 0.6):
			continue
		if s.kind == "dmg" and targets(u, s).tiles.is_empty():
			continue
		a = s
		break
	if a.is_empty():
		a = act(u, "basic")
	var p: Variant = pick(u, a)
	if p == null and reach_blocked(u, a) and _approach(u):
		return
	if p == null:
		_log("%s can’t find a target." % name_of(u))
		_step()
		return
	perform(u, a, p.x, p.y, 0)


## Under Reach, a melee foe with nobody across its lane steps toward the front row and the nearest lane with a target.
## Returns false if no step gets it closer.
func _approach(u: Dictionary) -> bool:
	var foes := living(opp(u.side))
	if foes.is_empty():
		return false
	var score := func(v: Vector2i) -> int:
		var lane_gap := 99
		for t in foes:
			lane_gap = mini(lane_gap, absi(v.y - t.c))
		return v.x + lane_gap
	var mv := act(u, "move")
	var best := Vector2i(u.r, u.c)
	var bs: int = score.call(best)
	for v in targets(u, mv).tiles:
		var s: int = score.call(v)
		if s < bs:
			bs = s
			best = v
	if best == Vector2i(u.r, u.c):
		return false
	perform(u, mv, best.x, best.y, 0)
	return true


func over() -> bool:
	if living("E").is_empty():
		result = "win"
		return true
	if living("P").is_empty():
		result = "lose"
		return true
	return false


func _finish() -> void:
	phase = "over"
	_log("Victory on round %d" % round_num if result == "win" else "Defeat on round %d" % round_num, "sys")


## Celerity: before round 1, every skill carrying it fires once, fastest unit first, at the AI's preferred target.
## The opener is not a chain link, its stun lasts at most 1 round, and the cooldown after depends on the card's stars.
## Returns true if the openers ended the battle.
func run_openers() -> bool:
	var openers := []
	for u in _by_speed(units.filter(func(x): return x.alive)):
		for i in u.skills.size():
			if u.skills[i].get("celerity", false):
				openers.append([u, i])
	if openers.is_empty():
		return false
	phase = "run"
	events.append({"t": "phase", "name": "opening"})
	_log("Opening volley", "sys")
	for o in openers:
		var u: Dictionary = o[0]
		var i: int = o[1]
		if not u.alive:
			continue
		var a := act(u, "s%d" % i)
		var opener := a
		if a.get("fx", {}).get("stun", 0) > 1:
			opener = a.duplicate(true)
			opener.fx.stun = 1
		var p: Variant = Vector2i(u.r, u.c) if opener.pattern == "all" else pick(u, opener)
		if p == null:
			continue
		perform(u, opener, p.x, p.y, 0)
		u.cd[i] = a.cd * Data.CELERITY_CD[u.get("stars", 1)]
		if over():
			return true
	phase = "plan"
	return false


## Fastest first; ties keep their order.
func _by_speed(us: Array) -> Array:
	var idx := range(us.size())
	idx.sort_custom(func(a, b): return us[a].spd > us[b].spd if us[a].spd != us[b].spd else a < b)
	return idx.map(func(i): return us[i])


func run_queue() -> Dictionary:
	var chain := 0
	var queued := {}
	var ctx := {"prev": "", "n": 0}
	for q in queue:
		queued[q.id] = true
		var u := unit(q.id)
		if u.is_empty() or not u.alive:
			continue
		if u.st.stun > 0:
			_stunned_skip(u)
			chain = 0
			ctx.prev = ""
			ctx.n = 0
			continue
		_take_step(u)
		if not u.alive:
			continue
		var a := act(u, q.key)
		perform(u, a, q.r, q.c, chain if a.is_skill else 0, ctx)
		chain = next_chain(chain, a)
		if a.get("breaks_chain", true) != false and not (a.is_skill and a.kind == "dmg"):
			ctx.prev = ""
			ctx.n = 0
		if over():
			return {"queued": queued, "done": true}
	return {"queued": queued, "done": false}


func end_of_round() -> void:
	var burned := []
	var ash: bool = rules.ashfall and round_num >= RULE_DEFS.ashfall.from
	for u in units.filter(func(x): return x.alive):
		if u.st.burn > 0 or ash:
			var d := maxi(1, roundi(u.max_hp * 0.06))
			u.hp -= d
			if u.st.burn > 0:
				u.st.burn -= 1
			_on_damaged(u)
			if u.side == "P":
				taken += d
			else:
				dealt += d
			_float(u, "-%d burn" % d, "burn")
			_flash(u.side, u.r, u.c)
			burned.append("%s %d" % [name_of(u), d])
			if u.hp <= 0:
				_fall(u, 0, "")
		u.st.guard = false
		u.cd = u.cd.map(func(v): return maxf(0.0, v - 1))
	if burned.size():
		_log("%s: %s" % ["Ashfall" if ash else "Burn", ", ".join(burned)])
		_step()
	for u in units.filter(func(x): return x.alive):
		_gain_stacks(u)
		u.rf = {"moved": false, "damaged": false}
		u.marks = u.marks.filter(func(m): return m.until > round_num)
	var fell := []
	for u in units.filter(func(x): return not x.alive and x.downed > 0):
		u.downed -= 1
		if u.downed == 0:
			u.fallen = true
			fell.append(name_of(u))
	if fell.size():
		_log("%s fell for the run: not revived in time." % ", ".join(fell))
	buffs = buffs.filter(func(b): return b.until > round_num)
	for e in tiles:
		e.rounds -= 1
	var gone := tiles.filter(func(e): return e.rounds <= 0)
	tiles = tiles.filter(func(e): return e.rounds > 0)
	if gone.size():
		_log("%s on %s fizzles out." % [gone[0].name, " and ".join(gone.map(func(e): return lane(e.r, e.c)))])


## Resolves the planned round: the queue, then unqueued heroes' basic attacks, then the enemies, then round end.
func run_round() -> void:
	if phase != "plan":
		return
	phase = "run"
	_log("Round %d" % round_num, "sys")
	events.append({"t": "phase", "name": "ally"})
	var q := run_queue()
	if q.done:
		_finish()
		return
	for u in _by_speed(living("P").filter(func(x): return not q.queued.has(x.id))):
		if not u.alive:
			continue
		if u.st.stun > 0:
			_stunned_skip(u)
			continue
		_take_step(u)
		if not u.alive:
			continue
		var a := act(u, "basic")
		var p: Variant = pick(u, a)
		if p != null:
			perform(u, a, p.x, p.y, 0)
		if over():
			_finish()
			return
	events.append({"t": "phase", "name": "enemy"})
	for u in _by_speed(living("E")):
		if not u.alive:
			continue
		enemy_turn(u)
		if over():
			_finish()
			return
	end_of_round()
	if over():
		_finish()
		return
	round_num += 1
	queue = []
	steps = {}
	phase = "plan"


## Where a hero can plan to step: empty tiles on their grid within `tune.step` tiles (counted across, not diagonally),
## not already claimed by another hero's planned step. Their own tile is included, to cancel a step.
func step_tiles(u: Dictionary) -> Array:
	var claimed := {}
	for id in steps:
		if id != u.id:
			claimed[steps[id]] = true
	var out := []
	for v in all_tiles():
		var here: bool = v == Vector2i(u.r, u.c)
		if absi(v.x - u.r) + absi(v.y - u.c) > tune.step or claimed.has(v):
			continue
		if here or (at(u.side, v.x, v.y).is_empty() and downed_at(u.side, v.x, v.y).is_empty()):
			out.append(v)
	return out


## Plans a step for a hero; stepping to their own tile clears it.
func plan_step(id: String, to: Vector2i) -> void:
	var u := unit(id)
	if u.is_empty() or not to in step_tiles(u):
		return
	if to == Vector2i(u.r, u.c):
		steps.erase(id)
	else:
		steps[id] = to


## The hero as they will stand when their turn comes, for aiming while planning (Reach, melee exposure).
func as_planned(u: Dictionary) -> Dictionary:
	if not steps.has(u.id):
		return u
	var p := u.duplicate()
	p.r = steps[u.id].x
	p.c = steps[u.id].y
	return p


## Resolving: the hero walks to their planned tile, unless someone got there first.
func _take_step(u: Dictionary) -> void:
	if not steps.has(u.id):
		return
	var to: Vector2i = steps[u.id]
	steps.erase(u.id)
	if not at(u.side, to.x, to.y).is_empty():
		_log("%s can’t step to %s: it’s taken." % [name_of(u), lane(to.x, to.y)])
		_step()
		return
	_log("%s steps to %s." % [name_of(u), lane(to.x, to.y)])
	move_unit(u, to.x, to.y, {})
	events.append({"t": "walk", "id": u.id, "r": to.x, "c": to.y})
	_step()


## Plans an action for a hero, replacing any it already had queued.
func enqueue(id: String, key: String, r: int, c: int) -> void:
	queue = queue.filter(func(q): return q.id != id)
	queue.append({"id": id, "key": key, "r": r, "c": c})


func dequeue(id: String) -> void:
	queue = queue.filter(func(q): return q.id != id)


## The queued entry for a hero, or empty.
func queued(id: String) -> Dictionary:
	for q in queue:
		if q.id == id:
			return q
	return {}
