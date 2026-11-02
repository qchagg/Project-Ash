class_name Collection
extends RefCounted
## The player's heroes: one card per hero, with a star level and augments. Everyone has four stars: a hero arrives at 1★,
## each new copy lights the next star, and copies past 4★ turn into embers.

## Four on the field for now. Design target (2026-10-21): five per team, six in rare cases; keep the code at four until then.
const MAX_SQUAD := 4
const DEFAULT_SQUAD := ["kaede", "brann", "sorrel", "ilse"]
const STAR_BONUS := 0.10
const MAX_STARS := 4
## What a spare copy past 4★ pays. A first guess.
const SPARE_EMBERS := 60
## Each side's grid: rows from the front (0) back, columns are lanes. 3 rows by 4 lanes for a squad of four;
## a fifth hero would bring back the fourth row.
const ROWS := 3
const COLS := 4

var cards: Array = []
var loose: Array = []
var squad: Array = []   # card uids on the field; a starter card's uid is its hero key
## Where each card stands on its side's grid (uid -> Vector2i(row, col), row 0 is the front). Unset cards use their hero's spot.
var formation := {}


func _init() -> void:
	reset()


func reset() -> void:
	cards = []
	for h in Data.HEROES:
		cards.append(new_card(h.key))
	loose = Data.AUGS.keys()
	squad = DEFAULT_SQUAD.duplicate()
	formation = {}


func new_card(hero_key: String) -> Dictionary:
	var h := Data.hero(hero_key)
	var base := {"max_hp": roundi(h.max_hp / 10.0) * 10, "atk": h.atk, "def": h.def, "spd": h.spd}
	return {"uid": hero_key, "hero": hero_key, "stars": 1, "base": base, "augs": []}


## A new copy of a hero lights their next star. Past 4★ it turns into embers, and the caller banks what this returns.
func add_copy(hero_key: String) -> int:
	var c := by(hero_key)
	if c.is_empty():
		return 0
	if c.stars >= MAX_STARS:
		return SPARE_EMBERS
	c.stars += 1
	return 0


func by(uid: String) -> Dictionary:
	for c in cards:
		if c.uid == uid:
			return c
	return {}


func stats(c: Dictionary) -> Dictionary:
	var m: float = 1 + STAR_BONUS * (c.stars - 1)
	var out := {}
	for k in Data.STATS:
		out[k] = roundi(c.base[k] * m)
	return out


func skills(c: Dictionary) -> Array:
	return Data.apply_augs(Data.hero(c.hero).skills, c.augs)


## A hero holds as many augments as they have stars, and augments swap in and out freely.
func slot_aug(uid: String, i: int, aug: String) -> bool:
	var c := by(uid)
	if c.is_empty() or not aug in loose or c.augs.size() >= c.stars or not Data.fits(aug, Data.hero(c.hero).skills[i]):
		return false
	loose.erase(aug)
	c.augs.append({"aug": aug, "skill": i})
	return true


func unslot_aug(uid: String, j: int) -> bool:
	var c := by(uid)
	if c.is_empty() or j >= c.augs.size():
		return false
	loose.append(c.augs[j].aug)
	c.augs.remove_at(j)
	return true


## Returns an empty string on success, or the reason the card can't move.
func toggle_field(uid: String) -> String:
	if uid in squad:
		if squad.size() == 1:
			return "Keep at least one card on the field."
		squad.erase(uid)
		return ""
	if squad.size() >= MAX_SQUAD:
		return "The field is full at %d. Bench a card first." % MAX_SQUAD
	squad.append(uid)
	# A card joining on a taken tile steps to the first free one, front row first.
	if at(tile(uid), uid) != "":
		formation[uid] = free_tile()
	return ""


## The tile a card starts a fight on: where the formation put it, or its hero's default spot.
func tile(uid: String) -> Vector2i:
	if formation.has(uid):
		return formation[uid]
	var h := Data.hero(by(uid).hero)
	return Vector2i(h.r, h.c)


## The fielded card standing on `t`, ignoring `except`; "" when the tile is empty.
func at(t: Vector2i, except := "") -> String:
	for u in squad:
		if u != except and tile(u) == t:
			return u
	return ""


## The first tile no fielded card stands on, scanning from the front row, left to right.
func free_tile() -> Vector2i:
	for r in ROWS:
		for c in COLS:
			if at(Vector2i(r, c)) == "":
				return Vector2i(r, c)
	return Vector2i(-1, -1)


## Moves a fielded card to `t`. A card already there swaps onto the mover's old tile.
## Returns an empty string on success, or the reason it can't move.
func place(uid: String, t: Vector2i) -> String:
	if not uid in squad:
		return "Only cards on the field take a place in the formation."
	if t.x < 0 or t.x >= ROWS or t.y < 0 or t.y >= COLS:
		return "That tile is off the grid."
	var from := tile(uid)
	var other := at(t, uid)
	if other != "":
		formation[other] = from
	formation[uid] = t
	return ""
