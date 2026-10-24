## Made by tools/organize-art.py from the art/ folder; run it again rather than editing this by hand.
## Each character's live face: the still, the clips by kind, the clip for each skill slot and the evolve chant.
class_name Faces
extends RefCounted

const FACES := {
	"brann": {"char": "brann", "still": "res://art/faces/brann.webp", "idle": ["brann-idle1", "brann-idle2"], "talk": ["brann-talk1", "brann-talk2"], "skills": ["brann-spell1", "brann-spell2"], "chant": "brann-spell1", "other": [], "moods": {}},
	"kaede": {"char": "surya", "still": "res://art/faces/surya.webp", "idle": ["surya-idle1", "surya-idle2"], "talk": ["surya-talk1", "surya-talk2"], "skills": ["surya-spell1", "surya-spell2"], "chant": "surya-spell1", "other": [], "moods": {}},
	"ilse": {"char": "varuni", "still": "res://art/faces/varuni.webp", "idle": ["varuni-idle1", "varuni-idle2"], "talk": ["varuni-talk1"], "skills": ["varuni-spell3", "varuni-spell2"], "chant": "varuni-spell1", "other": [], "moods": {}},
}


## The face of a hero (by game key), or {} if they have none yet.
static func of(key: String) -> Dictionary:
	return FACES.get(key, {})


## The clip a hero's skill plays as its cut-in (by slot: s0, s1), or "".
static func skill_clip(key: String, slot: String) -> String:
	var skills: Array = of(key).get("skills", [])
	var i := slot.substr(1).to_int()
	return skills[i] if slot.begins_with("s") and i < skills.size() else ""
