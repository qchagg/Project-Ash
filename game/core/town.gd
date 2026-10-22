class_name Town
extends RefCounted
## The town: meta-progression between expeditions. Buildings rise level by level, paid for in embers, and each level opens
## something in another system (the forge for evolving, the archive for chronicles, routes for new heroes).
## The Ashen Hearth is the town's fire: no other building can rise higher than it.

## Embers: the town's one resource. Battles bring them home; building spends them.
const START_EMBERS := 400
## Embers a won battle brings back before the Hearth's bonus.
const BATTLE_EMBERS := 120
## Each level of a building costs this much more than the last.
const GROWTH := 1.6

## Each building: what it is, its first cost, its highest level, the tab it feeds, and what each level gives
## (index 0 is level 1). Caravanserai and envoys add their region lines on top, from Data.REGIONS.
const BUILDINGS := {
	"hearth": {"name": "Ashen Hearth", "icon": "bld_hearth", "cost": 200, "max": 6, "link": "",
		"about": "The town's fire. Every building can rise as high as the Hearth, and no higher.",
		"levels": ["Buildings rise to level 1.", "Buildings rise to level 2. Battles bring 10% more embers.",
			"Buildings rise to level 3. Battles bring 20% more embers.", "Buildings rise to level 4. Battles bring 30% more embers.",
			"Buildings rise to level 5. Battles bring 40% more embers.", "Buildings rise to level 6. Battles bring 50% more embers."]},
	"forge": {"name": "The Forge", "icon": "bld_forge", "cost": 100, "max": 5, "link": "heroes", "enter": "to your heroes",
		"about": "Where copies of a hero are merged into one stronger card, and Ashcrowns are set.",
		"levels": ["Merge two copies of a hero.", "Preview a merge before you commit to it.",
			"Smelt a spare 3★ copy into an Ashcrown shard.", "Three shards set an Ashcrown.", "Set augments can be reforged once per card."]},
	"archive": {"name": "The Archive", "icon": "bld_archive", "cost": 100, "max": 5, "link": "archive", "enter": "open the archive",
		"about": "Scribes keep each hero's chronicle, and the histories of the regions they come from.",
		"levels": ["Chronicles: each hero's lore and home.", "Bonds are written into the chronicles.",
			"Scars are recorded.", "Regional histories open in the Codex.", "The lost chronicles of fallen foes."]},
	"caravanserai": {"name": "Caravanserai", "icon": "bld_caravanserai", "cost": 120, "max": 5, "link": "",
		"about": "Travellers rest here on the long roads. Open a route, and heroes from that region come to the town.",
		"levels": ["Routes to two regions.", "A third route.", "A fourth route.", "A fifth route.", "Every route is open."]},
	"grounds": {"name": "Training Grounds", "icon": "bld_grounds", "cost": 100, "max": 5, "link": "party", "enter": "to the party",
		"about": "Heroes drill their aptitudes for the trials met on the road: lore, charm, finesse, wits, resolve and might.",
		"levels": ["Trials: favored aptitudes roll d20 +3.", "Spar: train one unfavored aptitude to +1.",
			"Spar to +2.", "Mentors: bonded heroes train together, both gain +1.", "Favored aptitudes spark on 18–20."]},
	"infirmary": {"name": "Infirmary", "icon": "bld_infirmary", "cost": 90, "max": 5, "link": "",
		"about": "Healers who travel with the squad. On an expedition, every camp heals more for each level.",
		"levels": ["Camps heal 40% of health.", "Camps heal 50%.", "Camps heal 60%.", "Camps heal 75%.", "Camps heal everyone fully."]},
	"bazaar": {"name": "Spirit Bazaar", "icon": "bld_bazaar", "cost": 110, "max": 5, "link": "",
		"about": "Binders trade in elemental spirits. Each level brings another family of spirits to the stalls.",
		"levels": ["Salamanders: fire augments.", "Undines: water augments.", "Gnomes: earth augments.",
			"Sylphs: wind augments.", "Rebinding: move a set augment once per card."]},
	"envoys": {"name": "Hall of Envoys", "icon": "bld_envoys", "cost": 140, "max": 6, "link": "",
		"about": "Each region sends an envoy, and each envoy brings their people's favor to the whole squad.",
		"levels": ["An envoy takes the first seat.", "A second seat.", "A third seat.", "A fourth seat.", "A fifth seat.", "A sixth seat."]},
}

## What each region's envoy brings. Regions added later fall back to a plain line until they get one.
const FAVORS := {
	"jaladesh": "Healing skills restore 5% more.",
	"marusthal": "Charm trials roll +1, and caravans bring 10% more embers.",
	"khorvan": "Each hero's first move in a battle is free.",
	"gwyntmoor": "Ranged hits lose 5% less to distance.",
	"hraunvald": "Shields hold 5% more.",
	"vetroles": "Wits trials roll +1, and ambushes are seen coming.",
}

var embers := 0
var levels := {}


func _init() -> void:
	reset()


## A new town: the Hearth lit, the Forge and the Archive built, everything else waiting.
func reset() -> void:
	embers = START_EMBERS
	levels = {}
	for k in BUILDINGS:
		levels[k] = 0
	levels.hearth = 1
	levels.forge = 1
	# The Archive holds the codex and the settings, so it stands from the start.
	levels.archive = 1


func level(key: String) -> int:
	return levels.get(key, 0)


## The highest a building can stand right now: its own top level, held to the Hearth's for everything else.
func cap(key: String) -> int:
	var top: int = BUILDINGS[key].max
	return top if key == "hearth" else mini(top, level("hearth"))


## The embers to raise a building one level (or build it, from 0), rounded to tens.
func cost(key: String) -> int:
	return roundi(BUILDINGS[key].cost * pow(GROWTH, level(key)) / 10.0) * 10


## Why a building can't rise now, or "" when it can.
func blocked(key: String) -> String:
	if level(key) >= BUILDINGS[key].max:
		return "At its highest level."
	if level(key) >= cap(key):
		return "Raise the Ashen Hearth first."
	if embers < cost(key):
		return "Needs %d more embers." % (cost(key) - embers)
	return ""


## Builds or raises a building, paying its cost. Returns false and changes nothing when it is blocked.
func upgrade(key: String) -> bool:
	if blocked(key) != "":
		return false
	embers -= cost(key)
	levels[key] = level(key) + 1
	return true


## What a level of a building gives (1-based), with the region it opens where it opens one.
func gives(key: String, lvl: int) -> String:
	var line: String = BUILDINGS[key].levels[lvl - 1]
	match key:
		"caravanserai":
			var opened := routes_at(lvl).slice(routes_at(lvl - 1).size())
			if not opened.is_empty():
				return "%s to %s." % ["A route" if opened.size() == 1 else "Routes",
					" and ".join(opened.map(func(k): return Data.REGIONS[k].name))]
		"envoys":
			var regions := Data.REGIONS.keys()
			if lvl <= regions.size():
				var k: String = regions[lvl - 1]
				return "%s envoy: %s" % [Data.REGIONS[k].name, favor(k)]
	return line


## Region keys the caravanserai reaches at a level: two at level 1, one more each level after.
func routes_at(lvl: int) -> Array:
	var n := 0 if lvl <= 0 else lvl + 1
	if lvl >= BUILDINGS.caravanserai.max:
		n = Data.REGIONS.size()
	return Data.REGIONS.keys().slice(0, mini(n, Data.REGIONS.size()))


func routes() -> Array:
	return routes_at(level("caravanserai"))


## Region keys with a seated envoy, in seating order.
func envoys() -> Array:
	return Data.REGIONS.keys().slice(0, mini(level("envoys"), Data.REGIONS.size()))


static func favor(region: String) -> String:
	return FAVORS.get(region, "A favor from %s." % Data.REGIONS[region].name)


## Embers a won battle brings home, with the Hearth's bonus.
func battle_reward() -> int:
	return roundi(BATTLE_EMBERS * (1.0 + 0.1 * (level("hearth") - 1)))


func earn(n: int) -> void:
	embers += n
