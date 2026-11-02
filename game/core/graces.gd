class_name Graces
extends RefCounted
## The Graces of Mehfil: an order of dancers whose dance keeps the roads open. They are blessings rather than gods.
## Each has a figure in art/graces/ (cut by tools/grace-art.py, shipped beside the page in sheets/) and a blessing.
## Blessings are lore for now; shrines on the road will offer them.

const LIST := [
	{"key": "ashvini", "name": "Ashvini", "title": "the dawn spear", "elem": "",
		"lore": "She throws the first light of the day, and the road goes where it lands.",
		"blessing": "Your lead hero acts first in every fight."},
	{"key": "lehra", "name": "Lehra", "title": "the wind's refrain", "elem": "wind",
		"lore": "She hums a phrase once, and the wind carries it a hundred miles.",
		"blessing": "Wind heroes' skills come back a round sooner."},
	{"key": "tarini", "name": "Tarini", "title": "who turns the tide", "elem": "water",
		"lore": "She dances on the harbour wall until the sea forgets its anger.",
		"blessing": "When an ally is healed, the next ally in line heals a little too."},
	{"key": "sthira", "name": "Sthira", "title": "the held line", "elem": "earth",
		"lore": "She stands in the diamond and does not move, and the ground learns to hold.",
		"blessing": "Your front row starts every fight shielded."},
	{"key": "jvala", "name": "Jvala", "title": "the kept flame", "elem": "fire",
		"lore": "She carries a fire that has never gone out. She lends it; she never gives it away.",
		"blessing": "Burns you cause last a round longer."},
]


static func art_path(key: String) -> String:
	return "res://art/graces/%s.webp" % key
