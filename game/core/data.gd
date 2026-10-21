class_name Data
extends RefCounted
## Static game data and the pure rules on it, ported from sandbox/index.html.
## Keep the two in step until the sandbox retires.

const ELEMS := {
	"fire": {"label": "Fire", "spirit": "Salamander"},
	"water": {"label": "Water", "spirit": "Undine"},
	"earth": {"label": "Earth", "spirit": "Gnome"},
	"wind": {"label": "Wind", "spirit": "Sylph"},
}
# four: Water douses Fire, Fire consumes Wind, Wind erodes Earth, Earth dams Water; opposites (Fire–Earth, Wind–Water) are neutral.
# triangle: the v0.1 cycle, kept so the recorded reference fights still replay. Earth units fall back to their legacy_elem.
const BEATS := {
	"four": {"water": "fire", "fire": "wind", "wind": "earth", "earth": "water"},
	"triangle": {"fire": "wind", "wind": "water", "water": "fire"},
}
const ELEM_MULT := 1.5

# Tier and element colours from the Gilded Forge menus.
const TIER_COLORS := {1: Color("#a8744a"), 2: Color("#cfd5dc"), 3: Color("#e3c278"), 4: Color("#e3c278")}
const ELEM_COLORS := {
	"fire": [Color("#ff5a2a"), Color("#ffd27a"), Color("#ff6fa8"), Color("#b37bff")],
	"water": [Color("#43b8de"), Color("#c9f4ff"), Color("#8f9bff"), Color("#e2b8ff")],
	"earth": [Color("#d08a4a"), Color("#ffe08a"), Color("#6fd3a0"), Color("#c0506a")],
	"wind": [Color("#8ad46f"), Color("#effff2"), Color("#6fe0d8"), Color("#c4a6ff")],
}

const HEROES := [
	{"key": "kaede", "favored": ["charm", "finesse"], "bio": "A desert fox who talks his way into palaces and burns his way out.", "name": "Surya", "title": "Desert Fox", "elem": "fire", "range": "ranged",
		"max_hp": 820, "atk": 150, "def": 40, "spd": 92, "r": 1, "c": 1,
		"portrait": {"src": "res://art/portraits/kaede.webp", "x": 58, "y": 48, "zoom": 2.0}, "full": {"src": "res://art/full/kaede.webp", "x": 65, "w": 1.5, "face": [69, 26]}, "skills": [
		{"name": "Foxfire Lance", "flavor": "A spear of fox-light, thrown clean through every rank.", "kind": "dmg", "range": "ranged", "pattern": "pierce", "power": 1.25, "cd": 2, "fx": {"burn": 2}, "desc": "Spears an entire lane, front to back. Burns for 2 rounds."},
		{"name": "Ninefold Blaze", "flavor": "He lets the fire off its leash, and it finds everyone.", "kind": "dmg", "range": "ranged", "pattern": "all", "power": 0.7, "cd": 4, "fx": {"burn": 1}, "desc": "Nine tails of fire hit every enemy tile."}]},
	{"key": "brann", "favored": ["resolve", "might"], "bio": "[A line of bio goes here.]", "name": "Brann", "title": "Eternal Rider", "elem": "earth", "legacy_elem": "water", "range": "melee",
		"max_hp": 1400, "atk": 100, "def": 95, "spd": 70, "r": 0, "c": 1,
		"portrait": {"src": "res://art/portraits/brann.webp", "x": 54, "y": 44, "zoom": 2.0}, "full": {"src": "res://art/full/brann.webp", "x": 50, "w": 1.5, "face": [53, 11]}, "skills": [
		{"name": "Rockfall", "flavor": "The mountain answers when he charges.", "kind": "dmg", "range": "melee", "pattern": "single", "power": 1.4, "cd": 3, "fx": {"stun": 1}, "desc": "Heavy blow to an exposed enemy. Stuns it for its next action."},
		{"name": "Breakwater", "flavor": "He plants his feet, and the line holds.", "kind": "shield", "pattern": "all", "power": 1.9, "cd": 4, "desc": "Shields every ally. Shields hold until broken."}]},
	{"key": "sorrel", "favored": ["finesse", "wits"], "bio": "[A line of bio goes here.]", "name": "Sorrel", "title": "Gale Archer", "elem": "wind", "range": "ranged",
		"max_hp": 900, "atk": 135, "def": 45, "spd": 105, "r": 1, "c": 0,
		"portrait": {"src": "res://art/portraits/sorrel.webp", "x": 52, "y": 44, "zoom": 2.0}, "full": {"src": "res://art/full/sorrel.webp", "x": 50, "w": 1.4, "face": [51, 35]}, "skills": [
		{"name": "Crosswind", "flavor": "His arrows ride the gale four ways at once.", "kind": "dmg", "range": "ranged", "pattern": "cross", "power": 1.0, "cd": 2, "desc": "Hits a tile and its four neighbors."},
		{"name": "Pinning Shot", "flavor": "One arrow, and the target forgets how to move.", "kind": "dmg", "range": "ranged", "pattern": "single", "power": 1.7, "cd": 3, "fx": {"stun": 1}, "desc": "Precise shot that pins one target in place."}]},
	{"key": "ilse", "favored": ["lore", "charm"], "bio": "Tide chantress of Jaladesh, once cursed as a sea-witch.", "name": "Varuni", "title": "Tide Chantress", "elem": "water", "range": "ranged",
		"max_hp": 850, "atk": 95, "def": 50, "spd": 88, "r": 2, "c": 2,
		"portrait": {"src": "res://art/portraits/ilse-v2.webp", "x": 53, "y": 47, "zoom": 6.0}, "full": {"src": "res://art/full/ilse.webp", "x": 60, "w": 1.6, "origin": [29, 309], "face": [55, 22]},
		"cutin": "res://art/video/ilse-wave.ogv", "celebrate": "res://art/video/ilse-celebrate.ogv",
		"home": {"name": "Jaladesh", "desc": "A delta of a thousand channels, stilt villages and lotus lamps on the water."},
		"lore": "For years the delta ports sang of Varuni as a sea-witch: the chantress who called the tide down on a settler warship and drowned every man aboard. The songs never said what that ship was chasing. Three boats of refugees, fleeing the colonists who had burned their villages, slipped through the storm she raised and reached the mangroves alive. When the survivors' children finally told the truth, the same ports that had cursed her name hung lotus lamps along the water for her. By then she was gone again. Varuni has no use for being celebrated; she prefers the deep water, where no one calls her anything at all.", "skills": [
		{"name": "Riptide", "flavor": "The tide turns wherever she points.", "kind": "dmg", "range": "ranged", "pattern": "sweep", "power": 0.95, "cd": 2, "desc": "Washes across a full row."},
		{"name": "Rain of Renewal", "flavor": "A cool rain that washes away wounds and embers alike.", "kind": "heal", "pattern": "all", "power": 1.6, "cd": 3, "fx": {"cleanse": true}, "desc": "Heals every ally and clears burns."}]},
	# Playable versions of the Basalt Golem and Galeblade foes: same stats and kits, their own keys and art.
	{"key": "rock", "favored": ["might", "resolve"], "bio": "[A line of bio goes here.]", "name": "Basalt", "title": "Living Mountain", "elem": "earth", "range": "melee",
		"max_hp": 1500, "atk": 115, "def": 85, "spd": 60, "r": 0, "c": 2,
		"portrait": {"src": "res://art/portraits/rock.webp", "x": 47, "y": 43, "zoom": 4.6}, "full": {"src": "res://art/full/rock.webp", "x": 49, "w": 1.5, "face": [44, 16]}, "skills": [
		{"name": "Magma Fist", "flavor": "Stone, heated until it remembers being lava.", "kind": "dmg", "range": "melee", "pattern": "single", "power": 1.5, "cd": 3, "fx": {"burn": 2}, "desc": "A molten blow to one exposed enemy. Burns for 2 rounds."},
		{"name": "Quake", "flavor": "He stamps once, and the whole row loses its footing.", "kind": "dmg", "range": "melee", "pattern": "sweep", "power": 0.8, "cd": 3, "desc": "Shakes a full row."}]},
	{"key": "leaf", "favored": ["finesse", "wits"], "bio": "[A line of bio goes here.]", "name": "Galeblade", "title": "Thicket Duelist", "elem": "wind", "range": "melee",
		"max_hp": 950, "atk": 145, "def": 40, "spd": 110, "r": 0, "c": 0,
		"portrait": {"src": "res://art/portraits/leaf.webp", "x": 53, "y": 43, "zoom": 4.6}, "full": {"src": "res://art/full/leaf.webp", "x": 50, "w": 1.35, "face": [56, 35]}, "skills": [
		{"name": "Gust Step", "flavor": "A rustle of leaves, and he is already behind you.", "kind": "dmg", "range": "melee", "pattern": "single", "power": 1.6, "cd": 4, "fx": {"stun": 1}, "desc": "Steps through the wind to strike one enemy. Stuns it for its next action."},
		{"name": "Cyclone Cut", "flavor": "The thicket spins, and everything in it is cut.", "kind": "dmg", "range": "melee", "pattern": "sweep", "power": 1.0, "cd": 2, "desc": "A spinning cut across a full row."}]},
]

# Aptitudes for trials (d20 + bonus against the trial's difficulty), from the earlier Aptitudes screen.
# Each hero favours two: those roll +3 and spark on 19–20. Display only until trials are ported.
const APTITUDES := {
	"charm": "Persuade, barter, sway a bond",
	"lore": "Spirits, ruins, old magic",
	"finesse": "Climb, sneak, slip a lock",
	"wits": "Riddles, traps, quick thinking",
	"resolve": "Fear, curses, willpower",
	"might": "Lift, break, endure",
}
const FAVORED_BONUS := 3

# Bonds between heroes: friends, rivals or lovers. Each side has its own line about the other.
const BONDS := [
	{"a": "ilse", "b": "kaede", "kind": "best friends",
		"about_b": "The only one who never asked about the ship. He just kept the fire going.",
		"about_a": "The one woman who laughs at his charm instead of falling for it."},
]


## A hero's bonds, each as {other, kind, line}, written from that hero's side.
static func bonds(key: String) -> Array:
	var out := []
	for b in BONDS:
		if b.a == key:
			out.append({"other": b.b, "kind": b.kind, "line": b.about_b})
		elif b.b == key:
			out.append({"other": b.a, "kind": b.kind, "line": b.about_a})
	return out


# Augments slot into a skill whose tags they fit. Numbers add up; durations take the higher value.
# Each augment is a bound elemental spirit (Paracelsus's four): its family sets the card's aura, its prefix renames the skill.
const AUGS := {
	"keen": {"name": "Keen", "fam": "fire", "prefix": "Searing", "fits": ["damage"], "desc": "+15% damage. Stacks."},
	"kindling": {"name": "Kindling", "fam": "fire", "prefix": "Kindled", "fits": ["damage"], "desc": "Hits also Burn for 1 round. Does not stack."},
	"wellspring": {"name": "Wellspring", "fam": "water", "prefix": "Brimming", "fits": ["heal"], "desc": "+20% healing. Stacks."},
	"lingering": {"name": "Lingering", "fam": "water", "prefix": "Lingering", "fits": ["debuff"], "desc": "Stun and Burn last 1 round longer. Does not stack; stun caps at 2."},
	"bulwark": {"name": "Bulwark", "fam": "earth", "prefix": "Bedrock", "fits": ["shield"], "desc": "+20% shield. Stacks."},
	"hasten": {"name": "Hasten", "fam": "wind", "prefix": "Swift", "fits": ["any"], "desc": "Cooldown −1. Stacks, never below 1."},
	"celerity": {"name": "Celerity", "fam": "wind", "prefix": "Fleet", "fits": ["damage", "heal", "shield"], "desc": "Fires this skill as the battle starts. Then by stars: 1★ locked for the fight, 2★ double cooldown, 3★ normal cooldown, 4★ ready again."},
}
# Celerity's cooldown after the opener, by the card's stars (multiplier on the skill's cooldown; INF = locked).
const CELERITY_CD := {1: INF, 2: 2.0, 3: 1.0, 4: 0.0}
const STUN_CAP := 2
const STATS := ["max_hp", "atk", "def", "spd"]


static func hero(key: String) -> Dictionary:
	for h in HEROES:
		if h.key == key:
			return h
	return {}


static func beats(mode: String, a: String, b: String) -> bool:
	return BEATS[mode].get(a, "") == b


static func elem_mult(mode: String, a: String, b: String) -> float:
	if beats(mode, a, b):
		return ELEM_MULT
	if beats(mode, b, a):
		return 1.0 / ELEM_MULT
	return 1.0


static func skill_tags(s: Dictionary) -> Array:
	var t := []
	match s.kind:
		"dmg": t.append("damage")
		"heal": t.append("heal")
		"shield": t.append("shield")
	var fx: Dictionary = s.get("fx", {})
	if fx.get("stun", 0) or fx.get("burn", 0):
		t.append("debuff")
	return t


static func fits(aug: String, s: Dictionary) -> bool:
	var tags := skill_tags(s)
	for f in AUGS[aug].fits:
		if f == "any" or f in tags:
			return true
	return false


## The family with the most augments wins; a tie goes to the one slotted first. Strength 1–3 follows that family's count.
## Takes augment keys or {aug, skill} slots.
static func aura(augs: Array) -> Dictionary:
	var n := {}
	for a in augs:
		var fam: String = AUGS[a.aug if a is Dictionary else a].fam
		n[fam] = n.get(fam, 0) + 1
	var best := ""
	for f in n:
		if best == "" or n[f] > n[best]:
			best = f
	return {} if best == "" else {"fam": best, "lvl": mini(3, n[best])}


static func apply_augs(skills: Array, augs: Array) -> Array:
	var out := []
	for i in skills.size():
		var s: Dictionary = skills[i].duplicate(true)
		var mine := augs.filter(func(a): return a.skill == i).map(func(a): return a.aug)
		var n := func(k): return mine.count(k)
		if s.kind == "dmg": s.power *= 1 + 0.15 * n.call("keen")
		if s.kind == "heal": s.power *= 1 + 0.20 * n.call("wellspring")
		if s.kind == "shield": s.power *= 1 + 0.20 * n.call("bulwark")
		s.power = roundf(s.power * 1000) / 1000
		s.cd = maxi(1, s.cd - n.call("hasten"))
		if n.call("kindling"):
			var fx: Dictionary = s.get("fx", {})
			fx.burn = maxi(fx.get("burn", 0), 1)
			s.fx = fx
		if n.call("lingering") and s.has("fx"):
			if s.fx.get("stun", 0): s.fx.stun = mini(STUN_CAP, s.fx.stun + 1)
			if s.fx.get("burn", 0): s.fx.burn += 1
		if n.call("celerity"):
			s.celerity = true
		s.augs = mine
		if mine.size():
			# The skill takes the prefix of its leading family's first augment: Foxfire Lance + Kindling = Kindled Foxfire Lance.
			var lead: String = aura(mine).fam
			var first: String = mine.filter(func(k): return AUGS[k].fam == lead)[0]
			s.base_name = s.name
			s.name = AUGS[first].prefix + " " + s.name
		out.append(s)
	return out
