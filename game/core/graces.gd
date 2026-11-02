class_name Graces
extends RefCounted
## The Graces of Mehfil: an order of dancers whose dance keeps the roads open. They are blessings rather than gods.
## Each has a figure in art/graces/ (cut by tools/grace-art.py, shipped beside the page in sheets/) and a blessing.
## A shrine on the road offers three of them; the one you take blesses every fight for the rest of the run (Battle.bless).

const LIST := [
	{"key": "ashvini", "name": "Ashvini", "title": "the dawn spear", "elem": "",
		"lore": "She throws the first light of the day, and the road goes where it lands.",
		"blessing": "Every fight opens with her spear: your lead hero strikes first, before round 1."},
	{"key": "lehra", "name": "Lehra", "title": "the wind's refrain", "elem": "wind",
		"lore": "She hums a phrase once, and the wind carries it a hundred miles.",
		"blessing": "Wind heroes' skills come back a round sooner."},
	{"key": "tarini", "name": "Tarini", "title": "who turns the tide", "elem": "water",
		"lore": "She dances on the harbour wall until the sea forgets its anger.",
		"blessing": "At the end of every round the tide lifts your most wounded hero, healing 6% of their health."},
	{"key": "sthira", "name": "Sthira", "title": "the held line", "elem": "earth",
		"lore": "She stands in the diamond and does not move, and the ground learns to hold.",
		"blessing": "Your front row starts every fight shielded for 15% of their health."},
	{"key": "jvala", "name": "Jvala", "title": "the kept flame", "elem": "fire",
		"lore": "She carries a fire that has never gone out. She lends it; she never gives it away.",
		"blessing": "Burns you cause last a round longer."},
]

## The numbers behind the blessings: Ashvini's spear as a share of the lead hero's attack, Tarini's tide and
## Sthira's shield as shares of max health.
const SPEAR_POWER := 1.0
const TIDE := 0.06
const HOLD := 0.15
## How many Graces a shrine offers.
const OFFERS := 3


static func art_path(key: String) -> String:
	return "res://art/graces/%s.webp" % key


## A Grace by key, or {} for none.
static func by(key: String) -> Dictionary:
	for g in LIST:
		if g.key == key:
			return g
	return {}
