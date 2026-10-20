class_name Collection
extends RefCounted
## The player's cards: each copy of a hero has its own rolled stats, a star level and augments.
## Ported from the sandbox's cards section; the checks in tests/run_checks.gd hold it to the same results.

const MAX_SQUAD := 4
const DEFAULT_SQUAD := ["kaede", "brann", "sorrel", "ilse"]
const STAR_BONUS := 0.10

## best: a merge keeps the higher of each stat and every star adds STAR_BONUS. sum: the two cards' stats add up.
var merge_mode := "best"
var cards: Array = []
var loose: Array = []
var crowns := 0
var squad: Array = []   # card uids on the field; a starter card's uid is its hero key

var _seed := 7
var _seq := 0


func _init() -> void:
	reset()


## Seeded, so the starting collection rolls the same every time.
func reset() -> void:
	_seed = 7
	_seq = 0
	cards = []
	for h in Data.HEROES:
		cards.append(new_card(h.key, false))
	for k in ["kaede", "kaede", "ilse", "ilse", "brann", "sorrel"]:
		cards.append(new_card(k, true))
	loose = Data.AUGS.keys()
	crowns = 1
	squad = DEFAULT_SQUAD.duplicate()


func _rand() -> float:
	_seed = (_seed * 16807) % 2147483647
	return float(_seed - 1) / 2147483646.0


func new_card(hero_key: String, rolled: bool) -> Dictionary:
	var h := Data.hero(hero_key)
	var roll := func(x): return x * (0.85 + _rand() * 0.30) if rolled else float(x)
	# Rolled in this order (HP, attack, defence, speed) so the seeded collection matches the sandbox.
	var base := {}
	base.max_hp = roundi(roll.call(h.max_hp) / 10.0) * 10
	base.atk = roundi(roll.call(h.atk))
	base.def = roundi(roll.call(h.def))
	base.spd = roundi(roll.call(h.spd))
	if rolled:
		_seq += 1
	return {"uid": "%s-%d" % [hero_key, _seq] if rolled else hero_key, "hero": hero_key,
		"stars": 1, "bonus": true, "base": base, "augs": []}


func by(uid: String) -> Dictionary:
	for c in cards:
		if c.uid == uid:
			return c
	return {}


func stats(c: Dictionary) -> Dictionary:
	var m: float = 1 + STAR_BONUS * (c.stars - 1) if c.bonus else 1.0
	var out := {}
	for k in Data.STATS:
		out[k] = roundi(c.base[k] * m)
	return out


func skills(c: Dictionary) -> Array:
	return Data.apply_augs(Data.hero(c.hero).skills, c.augs)


## A card holds as many augments as it has stars. Free augments swap in and out; a merge sets them for good.
func slot_aug(uid: String, i: int, aug: String) -> bool:
	var c := by(uid)
	if c.is_empty() or not aug in loose or c.augs.size() >= c.stars or not Data.fits(aug, Data.hero(c.hero).skills[i]):
		return false
	loose.erase(aug)
	c.augs.append({"aug": aug, "skill": i, "locked": false})
	return true


func unslot_aug(uid: String, j: int) -> bool:
	var c := by(uid)
	if c.is_empty() or j >= c.augs.size() or c.augs[j].get("locked", false):
		return false
	loose.append(c.augs[j].aug)
	c.augs.remove_at(j)
	return true


## Two cards of the same star level, up to 2★, make one card a star higher. The base keeps its hero and skills.
## Fodder augments that fit a base skill fill free slots; the rest go loose. Everything left on the card is then set.
func merge(base_id: String, fodder_id: String) -> Dictionary:
	var b := by(base_id)
	var f := by(fodder_id)
	if b.is_empty() or f.is_empty() or base_id == fodder_id:
		return {"ok": false, "msg": "Pick two different cards."}
	if b.stars != f.stars:
		return {"ok": false, "msg": "Only cards of the same star level merge."}
	if b.stars >= 3:
		return {"ok": false, "msg": "3★ is as far as merging goes. An Ashcrown takes a 3★ to 4★."}
	var before := stats(b)
	var fs := stats(f)
	for k in Data.STATS:
		b.base[k] = before[k] + fs[k] if merge_mode == "sum" else maxi(b.base[k], f.base[k])
	if merge_mode == "sum":
		b.bonus = false
	b.stars += 1
	var sk: Array = Data.hero(b.hero).skills
	var carried := []
	var went_loose := []
	for a in f.augs:
		var i: int = a.skill if f.hero == b.hero else sk.find_custom(func(s): return Data.fits(a.aug, s))
		if i >= 0 and Data.fits(a.aug, sk[i]) and b.augs.size() < b.stars:
			b.augs.append({"aug": a.aug, "skill": i})
			carried.append(Data.AUGS[a.aug].name)
		else:
			loose.append(a.aug)
			went_loose.append(Data.AUGS[a.aug].name)
	for a in b.augs:
		a.locked = true
	cards.erase(f)
	squad.erase(f.uid)
	if squad.is_empty():
		squad = [b.uid]
	return {"ok": true, "before": before, "after": stats(b), "carried": carried, "loose": went_loose}


func crown(uid: String) -> bool:
	var c := by(uid)
	if c.is_empty() or c.stars != 3 or crowns < 1:
		return false
	crowns -= 1
	c.stars = 4
	return true


## Returns an empty string on success, or the reason the card can't move.
func toggle_field(uid: String) -> String:
	var c := by(uid)
	if uid in squad:
		if squad.size() == 1:
			return "Keep at least one card on the field."
		squad.erase(uid)
		return ""
	for u in squad:
		if by(u).hero == c.hero:
			return "Only one %s can take the field. Bench the other copy first." % Data.hero(c.hero).name
	if squad.size() >= MAX_SQUAD:
		return "The field is full at %d. Bench a card first." % MAX_SQUAD
	squad.append(uid)
	return ""
