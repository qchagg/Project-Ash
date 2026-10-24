## Made by tools/organize-art.py from the art/ folder; run it again rather than editing this by hand.
## Each character's live face: the still, the clips by kind, the clip for each skill slot and the evolve chant.
class_name Faces
extends RefCounted

const FACES := {
	"brann": {"char": "brann", "still": "res://art/faces/brann.webp", "idle": ["brann-idle1", "brann-idle2"], "talk": ["brann-talk1", "brann-talk2"], "skills": ["brann-spell1", "brann-spell2"], "chant": "brann-spell1", "other": [], "moods": {}},
	"seer": {"char": "seer", "still": "res://art/faces/seer.webp", "idle": ["seer-idle1", "seer-idle2"], "talk": ["seer-talk1", "seer-talk2"], "skills": ["seer-spell1", "seer-spell2"], "chant": "seer-spell1", "other": [], "moods": {}},
	"snake": {"char": "snake", "still": "res://art/faces/snake.webp", "idle": ["snake-idle1", "snake-idle2"], "talk": ["snake-talk1", "snake-talk2"], "skills": ["snake-spell1", "snake-spell2"], "chant": "snake-spell1", "other": [], "moods": {}},
	"sorrel": {"char": "sorrel", "still": "res://art/faces/sorrel.webp", "idle": ["sorrel-idle1", "sorrel-idle2"], "talk": ["sorrel-talk1", "sorrel-talk2"], "skills": ["sorrel-spell1", "sorrel-spell2"], "chant": "sorrel-spell1", "other": [], "moods": {}},
	"kaede": {"char": "surya", "still": "res://art/faces/surya.webp", "idle": ["surya-idle1", "surya-idle2"], "talk": ["surya-talk1", "surya-talk2"], "skills": ["surya-spell1", "surya-spell2"], "chant": "surya-spell1", "other": [], "moods": {}},
	"ilse": {"char": "varuni", "still": "res://art/faces/varuni.webp", "idle": ["varuni-idle1", "varuni-idle2"], "talk": ["varuni-talk1", "varuni-talk2"], "skills": ["varuni-spell3", "varuni-spell2"], "chant": "varuni-spell1", "other": [], "moods": {}},
}

## Battle sprites built from body uploads, by game key: they replace the src and idle in Data.SPRITES.
const BODIES := {
	"kaede": {"src": "res://art/sprites/surya.webp", "anim": {"w": 301, "h": 560, "cols": 9, "n": 61, "fps": 12, "src": "res://art/sprites/surya-idle.webp"}},
}


## The face of a hero (by game key), or {} if they have none yet.
static func of(key: String) -> Dictionary:
	return FACES.get(key, {})


## The clip a hero's skill plays as its cut-in (by slot: s0, s1), or "".
static func skill_clip(key: String, slot: String) -> String:
	var skills: Array = of(key).get("skills", [])
	var i := slot.substr(1).to_int()
	return skills[i] if slot.begins_with("s") and i < skills.size() else ""
