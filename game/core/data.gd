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
		"portrait": {"src": "res://art/portraits/kaede.webp", "eyes": [60, 43.5], "chin": 68.5, "crops": {"face": [26, 10, 63.5], "squad": [21.5, 7.5, 66.5], "tile": [7, 6, 68.5]}}, "full": {"src": "res://art/full/kaede.webp", "x": 65, "w": 1.5, "face": [69, 26]},
		"home": "marusthal",
		"lore": "Surya came to the court of Marusthal as a hostage, a fox-eared boy from a burned oasis, kept as a pledge for his family's good behaviour. He learned the palace the way other children learn prayers: which minister drinks, which queen is lonely, which door the guards forget. By twenty he was the most invited man in the city, and no one could say who had invited him first. He has seduced two treasuries, ended three betrothals and started a war of letters between rival rajas without drawing a blade. When charm runs out, there is foxfire. He says he is looking for the men who burned his oasis. He has been saying it for a long time, and he has never said what he will do when he finds them.", "lines": {
			"greet": ["Every palace has a back door. I just like to be invited through the front first.",
				"Smile. Rumours travel faster than fire, and I've started both today.",
				"You look like someone with a plan. Let me improve it."],
			"camp": ["Stars out here are better than any king's ceiling. I've compared.",
				"Wake me if anything's worth stealing. Or burning. Either.",
				"I'll tell you how I got out of Marusthal. Not the true version; the good one."]},
		"skills": [
		{"name": "Foxfire Lance", "flavor": "A spear of fox-light, thrown clean through every rank.", "kind": "dmg", "range": "ranged", "pattern": "pierce", "power": 1.25, "cd": 2, "fx": {"burn": 2}, "desc": "Spears an entire lane, front to back. Burns for 2 rounds."},
		{"name": "Ninefold Blaze", "flavor": "He lets the fire off its leash, and it finds everyone.", "kind": "dmg", "range": "ranged", "pattern": "all", "power": 0.7, "cd": 4, "fx": {"burn": 1}, "desc": "Nine tails of fire hit every enemy tile."}]},
	{"key": "brann", "favored": ["resolve", "might"], "bio": "The last rider of a broken host, still holding a border no one else remembers.", "name": "Brann", "title": "Eternal Rider", "elem": "earth", "legacy_elem": "water", "range": "melee",
		"max_hp": 1400, "atk": 100, "def": 95, "spd": 70, "r": 0, "c": 1,
		"portrait": {"src": "res://art/portraits/brann.webp", "eyes": [56, 43.5], "chin": 74.5, "crops": {"face": [18, 5.5, 72], "squad": [18, 1, 74.5]}}, "full": {"src": "res://art/full/brann.webp", "x": 50, "w": 1.85, "face": [55, 25]},
		"home": "khorvan",
		"lore": "Brann rode with the Ninth Host of the Khorvan Steppe, three thousand riders sworn to hold the Ashgate pass. When the pass fell, he was found under his horse with his face laid open from brow to cheek, the only one still breathing. The khans who gave the order are dead, the border has been redrawn twice, and a council he did not attend released the oath. He rides it anyway. Every spring he carves the names of the Ninth into the waystones along the pass, and every spring there is one more stone. Handsome, people say, until they see the scar; then they say it again, more quietly.", "lines": {
			"greet": ["The host is gone. The border isn't. Someone has to remember where it is.",
				"Speak plainly. I've had enough riddles from the dead.",
				"Point me at it. I'll hold."],
			"camp": ["Sleep. I've stood longer watches than this one.",
				"Eat while it's warm. On the old road we learned not to wait.",
				"My horse would have liked this fire. He liked very little."]},
		"skills": [
		{"name": "Rockfall", "flavor": "The mountain answers when he charges.", "kind": "dmg", "range": "melee", "pattern": "single", "power": 1.4, "cd": 3, "fx": {"stun": 1}, "desc": "Heavy blow to an exposed enemy. Stuns it for its next action."},
		{"name": "Breakwater", "flavor": "He plants his feet, and the line holds.", "kind": "shield", "pattern": "all", "power": 1.9, "cd": 4, "desc": "Shields every ally. Shields hold until broken."}]},
	{"key": "sorrel", "favored": ["finesse", "wits"], "bio": "A centaur archer who reads the wind like scripture and rarely needs a second arrow.", "name": "Sorrel", "title": "Gale Archer", "elem": "wind", "range": "ranged",
		"max_hp": 900, "atk": 135, "def": 45, "spd": 105, "r": 1, "c": 0,
		"portrait": {"src": "res://art/portraits/sorrel.webp", "eyes": [48.5, 40.5], "chin": 67, "crops": {"squad": [12, 7.5, 65.5], "tile": [0, 0.5, 73.5]}}, "full": {"src": "res://art/full/sorrel.webp", "x": 50, "w": 1.4, "face": [51, 35]},
		"home": "gwyntmoor",
		"lore": "The herds of Gwyntmoor teach their foals to read the wind before they read anything else, and Sorrel was the best reader the ridges had seen in a generation. He was also the vainest, which the herd forgave for exactly as long as he kept winning the autumn shoot. He left the year the elders ordered a raid on a rival herd's winter grazing; he would not loose an arrow at foals, and said so in front of everyone. Now he hires out his bow to anyone with a fair cause and a good table. He braids silver into his hair before every fight. If the wind is going to carry his name, he says, it may as well carry it looking well.", "lines": {
			"greet": ["The wind says you're about to ask me something. Go on.",
				"One arrow is a promise. Two is an apology. I don't apologise.",
				"Stand downwind of me; you'll hear more of the world."],
			"camp": ["The gale is resting too. Listen: it breathes slower at night.",
				"I'll take first watch. My eyes are better, and my legs don't tire.",
				"Every star is a fletching. Someone up there is a very good archer."]},
		"skills": [
		{"name": "Crosswind", "flavor": "His arrows ride the gale four ways at once.", "kind": "dmg", "range": "ranged", "pattern": "cross", "power": 1.0, "cd": 2, "desc": "Hits a tile and its four neighbors."},
		{"name": "Pinning Shot", "flavor": "One arrow, and the target forgets how to move.", "kind": "dmg", "range": "ranged", "pattern": "single", "power": 1.7, "cd": 3, "fx": {"stun": 1}, "desc": "Precise shot that pins one target in place."}]},
	{"key": "ilse", "favored": ["lore", "charm"], "bio": "Tide chantress of Jaladesh, once cursed as a sea-witch.", "name": "Varuni", "title": "Tide Chantress", "elem": "water", "range": "ranged",
		"max_hp": 850, "atk": 95, "def": 50, "spd": 88, "r": 2, "c": 2,
		"portrait": {"src": "res://art/portraits/ilse-v2.webp", "eyes": [51, 45], "chin": 56, "crops": {"face": [35.5, 30.5, 29.5], "squad": [36, 30.5, 29.5], "tile": [29.5, 30.5, 30]}}, "full": {"src": "res://art/full/ilse.webp", "x": 60, "w": 1.6, "origin": [29, 309], "face": [55, 22]},
		"lines": {
			"greet": ["The ports used to hang lamps for me. I liked it better when they cursed me; it was quieter.",
				"You called. The tide always answers, eventually. I am usually faster.",
				"Stand still. You are dripping on my patience."],
			"camp": ["Sleep. I will keep watch. The dark is only water without a shore.",
				"Drink something. Wounds close faster in a body that is not dry.",
				"Someone hum, please. The quiet out here is far too loud."]},
		"home": "jaladesh",
		"lore": "For years the delta ports sang of Varuni as a sea-witch: the chantress who called the tide down on a settler warship and drowned every man aboard. The songs never said what that ship was chasing. Three boats of refugees, fleeing the colonists who had burned their villages, slipped through the storm she raised and reached the mangroves alive. When the survivors' children finally told the truth, the same ports that had cursed her name hung lotus lamps along the water for her. By then she was gone again. Varuni has no use for being celebrated; she prefers the deep water, where no one calls her anything at all.", "skills": [
		{"name": "Riptide", "flavor": "The tide turns wherever she points.", "kind": "dmg", "range": "ranged", "pattern": "sweep", "power": 0.95, "cd": 2, "desc": "Washes across a full row."},
		{"name": "Rain of Renewal", "flavor": "A cool rain that washes away wounds and embers alike.", "kind": "heal", "pattern": "all", "power": 1.6, "cd": 3, "fx": {"cleanse": true}, "desc": "Heals every ally and clears burns."}]},
	# Playable versions of the Basalt Golem and Galeblade foes: same stats and kits, their own keys and art.
	{"key": "rock", "favored": ["might", "resolve"], "bio": "A mountain that woke up, and has not yet decided whether it likes people.", "name": "Basalt", "title": "Living Mountain", "elem": "earth", "range": "melee",
		"max_hp": 1500, "atk": 115, "def": 85, "spd": 60, "r": 0, "c": 2,
		"portrait": {"src": "res://art/portraits/rock.webp", "eyes": [45, 39], "chin": 52}, "full": {"src": "res://art/full/rock.webp", "x": 49, "w": 1.5, "face": [44, 16]},
		"home": "hraunvald",
		"lore": "The kings of Hraunvald carved their guardians from cooling lava and sang them awake, one for each gate of the fire-city. The kings are gone and the city lies under ash, but Basalt kept his gate for four hundred years after there was nothing left to guard. Travellers who sheltered in his doorway found a fire already lit and fish laid out to dry, and no one to thank. He walked away the morning a child asked him what he was waiting for, and he could not answer. He is slow to speak and slower to anger, and he still lights a fire for anyone who sleeps near him.", "skills": [
		{"name": "Magma Fist", "flavor": "Stone, heated until it remembers being lava.", "kind": "dmg", "range": "melee", "pattern": "single", "power": 1.5, "cd": 3, "fx": {"burn": 2}, "desc": "A molten blow to one exposed enemy. Burns for 2 rounds."},
		{"name": "Quake", "flavor": "He stamps once, and the whole row loses its footing.", "kind": "dmg", "range": "melee", "pattern": "sweep", "power": 0.8, "cd": 3, "desc": "Shakes a full row."}]},
	{"key": "leaf", "favored": ["finesse", "wits"], "bio": "A duelist sworn to guard the forest, and slowly becoming it.", "name": "Galeblade", "title": "Thicket Duelist", "elem": "wind", "range": "melee",
		"max_hp": 950, "atk": 145, "def": 40, "spd": 110, "r": 0, "c": 0,
		"portrait": {"src": "res://art/portraits/leaf.webp", "eyes": [53, 44.5], "chin": 54}, "full": {"src": "res://art/full/leaf.webp", "x": 50, "w": 1.35, "face": [56, 35]},
		"home": "vetroles",
		"lore": "Galeblade swore to guard Vetrolés for as long as the forest needed him, and the forest took him at his word. Each year the leaves grow further over him: first a cloak, then a mantle, now a thicket that rustles when there is no wind and no longer comes off. He has forgotten his face, and some mornings his name. He still challenges every trespasser to one duel, first blood, and still keeps his word to those who win. The woodcutters who knew him as a man leave bread at the old shrine. Lately it is not always gone by morning, and the paths have started to wander. They say the oath will be done when there is nothing left of him but forest. He has never said otherwise.", "skills": [
		{"name": "Gust Step", "flavor": "A rustle of leaves, and he is already behind you.", "kind": "dmg", "range": "melee", "pattern": "single", "power": 1.6, "cd": 4, "fx": {"stun": 1}, "desc": "Steps through the wind to strike one enemy. Stuns it for its next action."},
		{"name": "Cyclone Cut", "flavor": "The thicket spins, and everything in it is cut.", "kind": "dmg", "range": "melee", "pattern": "sweep", "power": 1.0, "cd": 2, "desc": "A spinning cut across a full row."}]},
]

# Aptitudes for trials (d20 + bonus against the trial's difficulty), from the earlier Aptitudes screen.
# Each hero favours two: those roll +3 and spark on 19–20. Display only until trials are ported.

## Home regions, drawn from cultures around the world (`inspired` names the influence). Each has a colorway, a dark and a light, after the Legends of Runeterra regions: the dark grounds
## its panels, the light carries its sigil (art/icons/ui/region_<key>.svg) and accents.
const REGIONS := {
	"jaladesh": {"name": "Jaladesh", "dark": Color("#0d2629"), "light": Color("#e895b4"),
		"desc": "A delta of a thousand channels, stilt villages and lotus lamps on the water.",
		"inspired": "The Bengal delta and the Sundarbans; Bangla and Sanskrit (jala, water)."},
	"marusthal": {"name": "Marusthal", "dark": Color("#2b1310"), "light": Color("#e6b47c"),
		"desc": "Salt-white dunes, red sandstone palace cities and caravans that travel by moonlight.",
		"inspired": "The Thar desert and the Rajput courts; Sanskrit (maru, desert)."},
	"khorvan": {"name": "Khorvan Steppe", "dark": Color("#161b1f"), "light": Color("#9fc4dc"),
		"desc": "An ocean of grass under an enormous sky, where the horse herds outnumber the people a hundred to one.",
		"inspired": "The Kazakh and Mongolian steppe."},
	"gwyntmoor": {"name": "Gwyntmoor", "dark": Color("#1b1722"), "light": Color("#b8a0d0"),
		"desc": "High moors where the wind never stops: stone circles, and centaur herds running the ridgelines.",
		"inspired": "Welsh uplands; Welsh (gwynt, wind)."},
	"hraunvald": {"name": "Hraunvald", "dark": Color("#121414"), "light": Color("#7ccbc1"),
		"desc": "Black lava fields that still steam, hot springs, and a fallen kingdom carved into the side of a volcano.",
		"inspired": "Iceland; Icelandic (hraun, lava field)."},
	"vetroles": {"name": "Vetrolés", "dark": Color("#0f1d14"), "light": Color("#93c96b"),
		"desc": "A windswept forest where the trees whisper and the paths rearrange themselves overnight.",
		"inspired": "Slavic forests; veter and les, wind and forest."},
	"djeliba": {"name": "Djeliba", "dark": Color("#141a33"), "light": Color("#f2c14e"),
		"desc": "A river empire of mudbrick cities and great libraries, where griots carry eight hundred years of history in song.",
		"inspired": "The Mali and Songhai empires, Timbuktu and Djenné; Bambara (Djeliba, the Niger, 'great river')."},
	"mwambao": {"name": "Mwambao", "dark": Color("#0f1f2a"), "light": Color("#f4846a"),
		"desc": "A coral-stone coast of carved doors and dhow harbours, where the monsoon decides who trades with whom.",
		"inspired": "The Swahili coast: Lamu, Zanzibar, Kilwa; Swahili (mwambao, coastline)."},
	"ritisuyu": {"name": "Ritisuyu", "dark": Color("#231a14"), "light": Color("#ef5a4c"),
		"desc": "Snow peaks above terraced valleys, rope bridges over gorges, and roads that runners cross in relays.",
		"inspired": "The Andes and Tawantinsuyu; Quechua (rit'i, snow; suyu, region)."},
	"xochitlan": {"name": "Xochitlan", "dark": Color("#0c1f1c"), "light": Color("#ff9f1c"),
		"desc": "A lake city of floating gardens and marigold causeways, ringed by jungle and hidden wells.",
		"inspired": "Tenochtitlan and the Maya lowlands; Nahuatl (xochitl, flower; -tlan, place of)."},
	"lautlangit": {"name": "Lautlangit", "dark": Color("#2a1a12"), "light": Color("#e8e2d0"),
		"desc": "A thousand volcanic islands where the sea and the sky meet, sailed by people who were born on boats.",
		"inspired": "The Malay archipelago; Malay and Indonesian (laut, sea; langit, sky)."},
}

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


## Full-body battle sprites (cut out, trimmed, feet on the bottom edge), by hero or foe key. `size` is each one's
## height against the others, set in the Battle Sprites viewer. `anim` is a sheet of idle frames (`cols` across).
## The golem has no full-body art yet, so it stands in with its waist-up cutout (`bust`).
const SPRITES := {
	"kaede": {"src": "res://art/sprites/surya.webp", "size": 1.05},
	"brann": {"src": "res://art/sprites/brann.webp", "size": 1.08},
	"sorrel": {"src": "res://art/sprites/sorrel.webp", "size": 1.08},
	"ilse": {"src": "res://art/sprites/varuni.webp", "size": 1.04,
		"anim": {"src": "res://art/sprites/varuni-idle.webp", "w": 436, "h": 560, "cols": 9, "n": 61, "fps": 12}},
	"leaf": {"src": "res://art/sprites/galeblade.webp", "size": 1.14},
	"blade": {"src": "res://art/sprites/galeblade.webp", "size": 1.14},
	"caller": {"src": "res://art/sprites/tidecaller.webp", "size": 1.10},
	"seer": {"src": "res://art/sprites/seer.webp", "size": 1.01},
	"golem": {"src": "res://art/full/rock.webp", "size": 1.2, "bust": true},
	"rock": {"src": "res://art/full/rock.webp", "size": 1.2, "bust": true},
}


## The battle sprite for a unit or hero (by its hero key, else its own key), or {} when it has none.
static var _sprites := {}


## A unit's battle sprite: its entry in SPRITES (size and all), with the src and idle of a body built from the
## art uploads (Faces.BODIES) laid over it.
static func sprite_for(u: Dictionary) -> Dictionary:
	var key: String = u.get("hero", u.get("key", ""))
	if not _sprites.has(key):
		var s: Dictionary = SPRITES.get(key, {}).duplicate()
		s.merge(Faces.BODIES.get(key, {}), true)
		_sprites[key] = s
	return _sprites[key]


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
